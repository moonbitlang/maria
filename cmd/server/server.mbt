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
  /// Working directory used for model loading and MoonBit module discovery.
  cwd : String
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
  model? : String,
  register? : RegisterInfo,
  serve~ : String,
  port~ : Int,
  cwd? : String,
  web_search? : Bool = false,
  system_prompt? : String,
) -> Server {
  let broadcast = @broadcast.Broadcast::new()
  let uuid = @uuid.generator(@rand.chacha8())
  guard @model.load(cwd?=cwd.map(cwd => cwd), name?=model) is Some(model) else {
    fail("Failed to load model '\{model}' from cwd '\{cwd}'")
  }
  let maria = @maria.Maria::new(model~, cwd?, web_search~, system_prompt?)
  maria.agent.add_listener((event : @event.Event) => broadcast.put(event))
  let http_server = @httpx.Server::new("[::]", port, reuse_addr=true)
  let port = http_server.port()
  if register is Some(register) {
    register.register(port~) |> ignore()
  } else {
    println(
      "[WARN] (Server) No register information provided; skipping registration.",
    )
    let pid = @spawn.getpid()
    println("[INFO] (Server \{pid}) Listening on port \{port}")
    println(
      "[INFO] (Server \{pid}) Visit http://localhost:\{port}/ to access the server.",
    )
  }
  let cwd = match cwd {
    Some(cwd) => cwd
    None => @os.cwd()
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
    cwd,
  }
}

///|
/// Central HTTP router that handles static files, REST endpoints, and SSE
/// streams behind the necessary CORS wrapper.
async fn Server::serve_http(self : Server) -> Unit {
  let file_server = @httpx.FileServer::new(self.serve)
  self.http_server.serve(
    @httpx.cors((r, w) => {
      println("[INFO] (Server) Received request: \{r.method_} \{r.path}")
      try {
        match (r.method_, r.path) {
          (Options, _) => w.write_header(204)
          (Get, "/") => {
            let index_html = html_read_file(
              @pathx.join(self.serve, "index.html"),
            )
            w.header().set("Content-Type", "text/html")
            w.write_header(200)
            w.write(index_html)
          }
          (Get, "/v1/status") =>
            w.send_json(code=200, {
              "status": self.status(),
              "web_search": self.maria.agent.web_search,
            })
          (Post, "/v1/cancel") => self.cancel_maria(w)
          (Get, "/v1/queued-messages") => self.get_queued_messages(w)
          (Get, "/v1/events") => self.get_events(w)
          (Post, "/v1/external-event/cancel") => self.send_cancellation_event(w)
          (Get, "/v1/tools") => self.get_tools(w)
          (Get, "/v1/system-prompt") => self.get_system_prompt(w)
          (Get, "/v1/moonbit/modules") => self.list_moonbit_modules(w)
          (Get, _) => file_server.handle(r, w)
          (
            Post,
            "/v1/message"
            | "/v1/external-event"
            | "/v1/external-event/diagnostics"
            | "/v1/external-event/user-message"
            | "/v1/enabled-tools"
            | "/v1/system-prompt"
            | "/v1/moonbit/publish",
          ) => {
            // Parse JSON once for all POST endpoints that need it
            let json = r.body.read_all().json() catch {
                error =>
                  raise json_error(400, "BadRequest", {
                    "error": {
                      "code": -1,
                      "message": "Invalid JSON in request body: \{error}",
                    },
                  })
              }
            match r.path {
              "/v1/message" => self.create_message(json, w)
              "/v1/external-event" => self.send_external_event(json, w)
              "/v1/external-event/diagnostics" =>
                self.send_diagnostics_event(json, w)
              "/v1/external-event/user-message" =>
                self.send_user_message_event(json, w)
              "/v1/enabled-tools" => self.set_enabled_tools(json, w)
              "/v1/moonbit/publish" => publish_moonbit_module(json, w)
              _ => fail("unreachable")
            }
          }
          _ =>
            w.send_json(code=404, {
              "error": { "code": -1, "message": "Unknown endpoint: \{r.path}" },
            })
        }
      } catch {
        HttpError(code~, reason~, body~) => {
          w.write_header(code, reason~)
          w.write(body)
        }
        error => raise error
      }
    }),
  )
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
        () => while true {
          let (msg, idq) = self.message_queue.get()
          let id = self.maria.agent.queue_message(
            msg.message,
            web_search?=msg.web_search,
          )
          idq.put((id, true))
        },
        no_wait=true,
      )
      idq.put((id, false))
      let task = group.spawn(
        () => {
          println("[INFO] (Server) Starting Maria task...")
          self.maria.agent.start() catch {
            error => {
              println("[ERROR] (Server) Maria task failed: \{error}")
              if !@async.is_being_cancelled() {
                self.broadcast.put(@event.Event::{
                  id: self.uuid.v4(),
                  desc: Failed(error.to_json()),
                })
              } else {
                self.broadcast.put(@event.Event::{
                  id: self.uuid.v4(),
                  desc: @event.Cancelled,
                })
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
/// Streams Maria lifecycle events plus queue synchronization messages over
/// Server-Sent Events.
async fn Server::get_events(self : Server, w : @httpx.ResponseWriter) -> Unit {
  let queued_messages : Array[Json] = self.maria.agent
    .queued_messages()
    .map(m => { "id": m.id, "message": m.message.to_openai() })
  w.header().set("Content-Type", "text/event-stream")
  w
  ..write_header(200)
  ..write("event: maria.queued_messages.synchronized\n")
  ..write("data: \{queued_messages.to_json().stringify()}\n\n")
  ..flush()
  self.broadcast.listen((hist, chan) => {
    for e in hist {
      chan.put(e)
    }
    for {
      let event = chan.get()
      if event.desc is (TokenCounted(_) | ContextPruned(_)) {
        continue
      }
      w
      ..write("event: maria\n")
      ..write("data: \{event.to_json().stringify()}\n\n")
      ..flush()
      if event.desc is (MessageQueued(_) | MessageUnqueued(_)) {
        let queued_messages : Array[Json] = self.maria.agent
          .queued_messages()
          .map(m => { "id": m.id, "message": m.message.to_openai() })
        w
        ..write("event: maria.queued_messages.synchronized\n")
        ..write("data: \{queued_messages.to_json().stringify()}\n\n")
        ..flush()
      }
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
    raise json_error(400, "BadRequest", {
      "error": "Missing 'type' field in request body",
    })
  }
  let queue = self.maria.agent.external_events()
  match event_type {
    "Cancelled" => queue.send(@event.Cancelled)
    "UserMessage" => {
      guard json is { "message": String(message), .. } else {
        raise json_error(400, "BadRequest", {
          "error": "Missing 'message' field for UserMessage event",
        })
      }
      queue.send(UserMessage(message))
    }
    "Diagnostics" => {
      guard json is { "diagnostics": String(diagnostics_jsonl), .. } else {
        raise json_error(400, "BadRequest", {
          "error": "Missing 'diagnostics' field for Diagnostics event",
        })
      }
      let diagnostics = @diagnostics.from_jsonl(diagnostics_jsonl)
      queue.send(Diagnostics(diagnostics))
    }
    _ =>
      raise json_error(400, "BadRequest", {
        "error": "Unknown event type: \{event_type}. Expected 'UserMessage', 'Cancelled', or 'Diagnostics'",
      })
  }
  w.send_json(code=200, { "success": true })
}

///|
/// Sends diagnostics from the IDE to the agent.
///
/// Request body:
/// ```json
/// {
///   "diagnostics": "...<JSONL string>..."  // or
///   "diagnostics": [ { "error_code": ..., "level": ..., "loc": ..., "message": ... }, ... ]
/// }
/// ```
async fn Server::send_diagnostics_event(
  self : Server,
  json : Json,
  w : @httpx.ResponseWriter,
) -> Unit {
  let diagnostics = match json {
    { "diagnostics": String(jsonl), .. } => @diagnostics.from_jsonl(jsonl)
    { "diagnostics": Array(_) as arr, .. } =>
      // Convert JSON array to JSONL and parse
      @diagnostics.from_jsonl(
        arr.stringify(), // This works because from_jsonl handles JSON per line
      )
    _ =>
      raise json_error(400, "BadRequest", {
        "error": "Missing 'diagnostics' field in request body",
      })
  }
  self.maria.agent.external_events().send(Diagnostics(diagnostics))
  w.send_json(code=200, {
    "success": true,
    "count": diagnostics.length().to_json(),
  })
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
    raise json_error(400, "BadRequest", {
      "error": "Missing 'message' field in request body",
    })
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
