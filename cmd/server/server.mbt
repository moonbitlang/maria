///|
/// Runtime container that binds the Maria agent, HTTP server, and broadcast
/// machinery needed to expose the API surface described in `README.md`.
struct Server {
  uuid : @uuid.Generator
  /// Long-lived Maria runtime plus agent state machine.
  maria : @maria.Maria
  /// SSE fan-out used to push events to every connected client.
  broadcast : @broadcast.Broadcast[@event.Event]
  /// Incoming message queue; each entry carries a reply channel to report
  /// whether it started immediately or was queued.
  message_queue : @aqueue.Queue[
    (CreateMessageRequest, @aqueue.Queue[(@uuid.Uuid, Bool)]),
  ]
  /// Handle to the currently running Maria task (when any) so we can cancel or
  /// report busy/idle status.
  mut task : @async.Task[Unit]?
  /// Directory served as static assets (usually `cmd/server`).
  serve : String
  /// TCP port bound by the underlying HTTP server.
  port : Int
  /// Underlying HTTP listener that dispatches all endpoints.
  http_server : @httpx.Server
}

///|
fn Server::status(self : Server) -> Status {
  match self.task {
    None => Status::Idle
    Some(_) => Status::Busy
  }
}

///|
pub fn Server::port(self : Server) -> Int {
  self.port
}

///|
/// Boots Maria, wires the SSE broadcast pipeline, optionally registers with a
/// daemon, and binds an `@httpx.Server`. The returned handle is ready to
/// `start()`.
pub async fn Server::new(
  name? : String,
  model? : String,
  register? : RegisterInfo,
  serve~ : String,
  port~ : Int,
  home? : String,
  cwd? : String,
  web_search? : Bool = false,
  resume_id? : @uuid.Uuid,
) -> Server {
  let home = match home {
    Some(home) => home
    None => @os.home()
  }
  let broadcast = @broadcast.Broadcast::new()
  let uuid = @uuid.generator(@rand.chacha8())
  guard @model.load(home~, name?=model) is Some(model) else {
    fail("Failed to load model '\{model}' from cwd '\{cwd}'")
  }
  let maria = if resume_id is Some(resume_id) {
    @maria.Maria::resume_(model~, resume_id, web_search~)
  } else {
    @maria.Maria::new(name?, model~, cwd?, web_search~)
  }
  maria.agent.add_listener((event : @event.Event) => broadcast.put(event))
  let http_server = @httpx.Server::new("[::]", port, reuse_addr=true)
  let port = http_server.port()
  if register is Some(register) {
    register.register(
      port~,
      new_id=maria.agent.id(),
      web_search=maria.agent.web_search,
      cwd=maria.agent.cwd,
      model=maria.agent.model.name,
    )
    |> ignore()
  } else {
    logger.warn("No register information provided; skipping registration.")
    let pid = @spawn.getpid()
    logger.info("Listening on port \{port}", data={ "pid": pid })
    logger.info("Visit http://localhost:\{port}/ to access the server.", data={
      "pid": pid,
    })
  }
  Server::{
    uuid,
    maria,
    broadcast,
    message_queue: @aqueue.new(kind=Unbounded),
    task: None,
    serve,
    port,
    http_server,
  }
}

///|
/// Central HTTP router that handles static files, REST endpoints, and SSE
/// streams behind the necessary CORS wrapper.
async fn Server::serve_http(self : Server) -> Unit {
  let router = @httpx.Router::new()
  router.add_handler(Get, "/v1/status", (_, w) => {
    let w = @httpx.JsonResponseWriter::new(w)
    w.write_header(200)
    w.write_json({
      "status": self.status(),
      "web_search": self.maria.agent.web_search,
    })
  })
  router.add_handler(Post, "/v1/cancel", (_, w) => self.cancel_maria(w))
  router.add_handler(Get, "/v1/queued-messages", (_, w) => {
    self.get_queued_messages(w)
  })
  router.add_handler(Get, "/v1/events", (_, w) => self.get_events(w))
  router.add_handler(Post, "/v1/external-event/cancel", (_, w) => {
    self.send_cancellation_event(w)
  })
  router.add_handler(Get, "/v1/tools", (_, w) => self.get_tools(w))
  router.add_handler(Get, "/v1/system-prompt", (_, w) => {
    self.get_system_prompt(w)
  })
  router.add_handler(Post, "/v1/message", (r, w) => self.create_message(r, w))
  router.add_handler(Post, "/v1/external-event", (r, w) => {
    let r = @httpx.JsonRequestReader::new(r)
    self.send_external_event(r.read_json(), w)
  })
  router.add_handler(Post, "/v1/external-event/user-message", (r, w) => {
    let r = @httpx.JsonRequestReader::new(r)
    self.send_user_message_event(r.read_json(), w)
  })
  router.add_handler(Post, "/v1/enabled-tools", (r, w) => {
    let r = @httpx.JsonRequestReader::new(r)
    self.set_enabled_tools(r.read_json(), w)
  })
  router.add_handler(Post, "/v1/system-prompt", (r, w) => {
    let r = @httpx.JsonRequestReader::new(r)
    self.set_system_prompt(r.read_json(), w)
  })
  let file_server = @httpx.FileServer::new(self.serve)
  router.set_not_found_handler((r, w) => file_server.handle(r, w))
  self.http_server.serve(@httpx.cors(router.handler()))
}

///|
/// Background worker that drains the inbound queue, kicks off the Maria agent,
/// and mirrors failures into the broadcast stream.
async fn Server::start_maria(self : Server) -> Unit {
  while true {
    @async.with_task_group(group => {
      let (msg, idq) = self.message_queue.get()
      let id = self.maria.agent.queue_message(
        msg.message,
        web_search?=msg.web_search,
      )
      group.spawn_bg(
        () => {
          while true {
            let (msg, idq) = self.message_queue.get()
            let id = self.maria.agent.queue_message(
              msg.message,
              web_search?=msg.web_search,
            )
            idq.put((id, true))
          }
        },
        no_wait=true,
      )
      idq.put((id, false))
      let task = group.spawn(
        () => {
          logger.info("Starting Maria task...")
          self.maria.agent.start() catch {
            error => {
              logger.error("Maria task failed: \{error}")
              if !@async.is_being_cancelled() {
                self.broadcast.put(
                  @event.Event::new(id=self.uuid.v4(), Failed(error.to_json())),
                )
              } else {
                self.broadcast.put(
                  @event.Event::new(id=self.uuid.v4(), @event.Cancelled),
                )
              }
              raise error
            }
          }
        },
        allow_failure=true,
      )
      self.task = Some(task)
      defer {
        self.task = None
      }
      task.wait() catch {
        _ => ()
      }
    })
  }
}

///|
async fn @httpx.ResponseWriter::send_json(
  self : Self,
  code~ : Int,
  json : Json,
) -> Unit {
  self.header().set("Content-Type", "application/json")
  self.write_header(code)
  self.write(json.stringify())
}

///|
/// Cancels the running agent (if any) and returns the pending queue back to
/// the client so UIs can decide what to do next.
async fn Server::cancel_maria(self : Server, w : @httpx.ResponseWriter) -> Unit {
  guard self.task is Some(task) else {
    w.send_json(code=404, {
      "error": { "code": -1, "message": "No running task to cancel." },
    })
  }
  task.cancel()
  let pms = self.maria.agent.clear_inputs()
  w.send_json(code=200, { "pending_messages": pms.to_json() })
}

///|
/// Runs the HTTP server alongside the background Maria worker until the
/// process is cancelled.
pub async fn Server::start(self : Server) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(() => self.start_maria(), allow_failure=true)
    self.serve_http()
  })
}

///|
pub(all) enum ServerStreamEvent {
  MariaQueuedMessagesSynchronized(Array[@agent.QueuedMessage])
  Maria(@event.Event)
}

///|
pub impl @httpx.FromEvent for ServerStreamEvent with from_event(
  event : @httpx.Event,
) -> ServerStreamEvent raise {
  let { event, data } = event
  let data = @json.parse(data)
  match event {
    Some("maria.queued_messages.synchronized") =>
      ServerStreamEvent::MariaQueuedMessagesSynchronized(@json.from_json(data))
    Some("maria") => ServerStreamEvent::Maria(@json.from_json(data))
    _ => fail("unrecognized event type: \{event}")
  }
}

///|
pub impl @httpx.ToEvent for ServerStreamEvent with to_event(
  self : ServerStreamEvent,
) -> @httpx.Event {
  match self {
    ServerStreamEvent::MariaQueuedMessagesSynchronized(queued_messages) =>
      @httpx.Event::new(
        event="maria.queued_messages.synchronized",
        data=queued_messages.to_json().stringify(),
      )
    ServerStreamEvent::Maria(event) =>
      @httpx.Event::new(event="maria", data=event.to_json().stringify())
  }
}

///|
/// Streams Maria lifecycle events plus queue synchronization messages over
/// Server-Sent Events.
async fn Server::get_events(self : Server, w : @httpx.ResponseWriter) -> Unit {
  let w = @httpx.EventStreamWriter::new(w)
  w.write_header(200)
  w.write(MariaQueuedMessagesSynchronized(self.maria.agent.queued_messages()))
  self.broadcast.listen_forever(event => {
    if event.desc is (TokenCounted(_) | ContextPruned(_)) {
      return
    }
    w.write(Maria(event))
    if event.desc is (MessageQueued(_) | MessageUnqueued(_)) {
      w.write(
        MariaQueuedMessagesSynchronized(self.maria.agent.queued_messages()),
      )
    }
  })
}

///|
/// Returns the queued messages as JSON without keeping the connection open.
async fn Server::get_queued_messages(
  self : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  let queued_messages : Array[Json] = self.maria.agent
    .queued_messages()
    .map(m => { "id": m.id, "message": m.message.to_openai() })
  w.send_json(code=200, queued_messages.to_json())
}

///|
/// Lists the registered tools and whether each one is currently enabled.
async fn Server::get_tools(self : Server, w : @httpx.ResponseWriter) -> Unit {
  let tools = self.maria.agent.tools()
  let tools_json : Map[String, Json] = {}
  for name, tool in tools {
    tools_json[name] = { "enabled": tool.enabled() }
  }
  w.send_json(code=200, Json::object(tools_json))
}

///|
/// Returns the current system prompt (or `null` when none is configured).
async fn Server::get_system_prompt(
  self : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  let res : Json = match self.maria.agent.system_prompt() {
    Some(sys) => sys.to_json()
    None => Json::null()
  }
  w.send_json(code=200, res)
}

///|
/// Sends a generic external event to the agent.
///
/// Request body:
/// ```json
/// {
///   "type": "UserMessage" | "Cancelled" | "Diagnostics",
///   "message": "...",  // for UserMessage
///   "diagnostics": "..."  // JSONL string for Diagnostics
/// }
/// ```
async fn Server::send_external_event(
  self : Server,
  json : Json,
  w : @httpx.ResponseWriter,
) -> Unit {
  guard json is { "type": String(event_type), .. } else {
    raise @httpx.JsonError::new(
      @status.BadRequest,
      "Missing 'type' field in request body",
    )
  }
  let queue = self.maria.agent.external_events()
  match event_type {
    "Cancelled" => queue.send(@event.Cancelled)
    "UserMessage" => {
      guard json is { "message": String(message), .. } else {
        raise @httpx.JsonError::new(
          @status.BadRequest,
          "Missing 'message' field for UserMessage event",
        )
      }
      queue.send(UserMessage(message))
    }
    _ =>
      raise @httpx.JsonError::new(
        @status.BadRequest,
        "Unknown event type: \{event_type}. Expected 'UserMessage' or 'Cancelled'",
      )
  }
  w.send_json(code=200, { "success": true })
}

///|
/// Sends an immediate user message to the agent.
///
/// Request body:
/// ```json
/// {
///   "message": "Please stop and focus on this instead..."
/// }
/// ```
async fn Server::send_user_message_event(
  self : Server,
  json : Json,
  w : @httpx.ResponseWriter,
) -> Unit {
  guard json is { "message": String(message), .. } else {
    raise @httpx.JsonError::new(
      @status.BadRequest,
      "Missing 'message' field in request body",
    )
  }
  self.maria.agent.external_events().send(UserMessage(message))
  w.send_json(code=200, { "success": true })
}

///|
/// Sends a Cancelled event to the agent.
/// This will cause the agent to stop at the next poll point.
async fn Server::send_cancellation_event(
  self : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  self.maria.agent.external_events().send(Cancelled)
  w.send_json(code=200, { "success": true })
}
