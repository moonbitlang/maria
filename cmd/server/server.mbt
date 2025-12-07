///|
struct Server {
  maria : @maria.Maria
  broadcast : @broadcast.Broadcast[Json]
  message_queue : @aqueue.Queue[
    (CreateMessageRequest, @aqueue.Queue[(@uuid.Uuid, Bool)]),
  ]
  mut task : @async.Task[Unit]?
  register : Register?
  serve : String
  port : Int
  http_server : @httpx.Server
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
pub async fn Server::new(
  model? : String,
  register? : Register,
  serve~ : String,
  port~ : Int,
  cwd? : String,
  web_search? : Bool = false,
) -> Server {
  let broadcast : @broadcast.Broadcast[Json] = @broadcast.Broadcast::new()
  let uuid = @uuid.generator(@rand.chacha8())
  guard @model.load(cwd?=cwd.map(cwd => cwd), name?=model) is Some(model) else {
    fail("Failed to load model '\{model}' from cwd '\{cwd}'")
  }
  let maria = @maria.Maria::new(model~, cwd?, web_search~)
  maria.agent.add_listener(event => {
    let event = event.to_json()
    guard event is Object(event) else { return }
    event["id"] = uuid.v4().to_string().to_json()
    broadcast.put(Json::object(event))
  })
  let http_server = @httpx.Server::new("[::]", port, reuse_addr=true)
  let port = http_server.port()
  let cwd = match cwd {
    Some(cwd) => cwd
    None => @os.cwd()
  }
  Server::{
    maria,
    broadcast,
    message_queue: @aqueue.new(kind=Unbounded),
    task: None,
    register,
    serve,
    port,
    http_server,
    cwd,
  }
}

///|
async fn Server::register(self : Server) -> Unit {
  guard self.register is Some(register) else {
    println(
      "[WARN] (Server) No register information provided; skipping registration.",
    )
    let pid = @spawn.getpid()
    println("[INFO] (Server \{pid}) Listening on port \{self.port}")
    println(
      "[INFO] (Server \{pid}) Visit http://localhost:\{self.port}/ to access the server.",
    )
    return
  }
  println("[INFO] (Server \{register.id}) Listening on port \{self.port}")
  println(
    "[INFO] (Server \{register.id}) Visit http://localhost:\{self.port}/ to access the server.",
  )
  let (r, b) = @http.post(
    "http://\{register.host}:\{register.port}/v1/task/register",
    Json::object({ "id": register.id, "port": self.port }),
  )
  guard r.code is (200..=299) else {
    raise json_error(500, "InternalServerError", {
      "error": {
        "code": r.code,
        "message": r.reason,
        "metadata": { "body": b.text() },
      },
    })
  }
}

///|
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
              @path.join(self.serve, "index.html"),
            )
            w.header().set("Content-Type", "text/html")
            w.write_header(200)
            w.write(index_html)
          }
          (Get, "/v1/status") => {
            let response : Json = {
              "status": self.status(),
              "web_search": self.maria.agent.web_search,
            }
            w.header().set("Content-Type", "application/json")
            w.write_header(200)
            w.write(response.stringify())
          }
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
              "/v1/system-prompt" => self.set_system_prompt(json, w)
              "/v1/moonbit/publish" => publish_moonbit_module(json, w)
              _ => fail("unreachable")
            }
          }
          _ => {
            w.header().set("Content-Type", "application/json")
            w.write_header(404)
            w.write(
              Json::object({
                "error": {
                  "code": -1,
                  "message": "Unknown endpoint: \{r.path}",
                },
              }),
            )
          }
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
                self.broadcast.put(
                  Json::object({
                    "msg": "MariaFailed",
                    "error": {
                      "code": -1,
                      "message": error.to_string(),
                      "metadata": error,
                    },
                  }),
                )
              } else {
                self.broadcast.put(
                  Json::object({
                    "msg": "MariaCancelled",
                    "error": { "code": -1, "message": "Task was cancelled." },
                  }),
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
async fn Server::cancel_maria(self : Server, w : @httpx.ResponseWriter) -> Unit {
  guard self.task is Some(task) else {
    w.header().set("Content-Type", "application/json")
    w.write_header(404)
    w.write(
      Json::object({
        "error": { "code": -1, "message": "No running task to cancel." },
      }),
    )
  }
  task.cancel()
  let pms = self.maria.agent.clear_inputs()
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(Json::object({ "pending_messages": pms.to_json() }))
}

///|
pub async fn Server::start(self : Server) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(() => self.start_maria(), allow_failure=true)
    self.register()
    self.serve_http()
  })
}

///|
async fn Server::get_events(self : Server, w : @httpx.ResponseWriter) -> Unit {
  w.header().set("Content-Type", "text/event-stream")
  w.write_header(200)
  w.write("event: maria.queued_messages.synchronized\n")
  let queued_messages : Array[Json] = []
  for m in self.maria.agent.queued_messages() {
    queued_messages.push({
      "id": m.id,
      "message": m.message.to_openai().to_json(),
    })
  }
  w.write("data: \{queued_messages.to_json().stringify()}\n\n")
  w.flush()
  self.broadcast.listen((hist, chan) => {
    for e in hist {
      chan.put(e)
    }
    for {
      let event = chan.get()
      if event is { "msg": "TokenCounted" | "ContextPruned", .. } {
        continue
      }
      // Skip over tool events (subagent events)
      if event is { "tool": { "name": String(_), "id": _, .. }, .. } {
        continue
      }
      w.write("event: maria\n")
      w.write("data: \{event.stringify()}\n\n")
      w.flush()
      if event is { "msg": "MessageQueued" | "MessageUnqueued", .. } {
        w.write("event: maria.queued_messages.synchronized\n")
        let queued_messages : Array[Json] = []
        for m in self.maria.agent.queued_messages() {
          queued_messages.push({
            "id": m.id,
            "message": m.message.to_openai().to_json(),
          })
        }
        w.write("data: \{queued_messages.to_json().stringify()}\n\n")
        w.flush()
      }
    }
  })
}

///|
async fn Server::get_queued_messages(
  self : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  let queued_messages : Array[Json] = []
  for m in self.maria.agent.queued_messages() {
    queued_messages.push({
      "id": m.id,
      "message": m.message.to_openai().to_json(),
    })
  }
  let response : Json = queued_messages.to_json()
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.stringify())
}

///|
async fn Server::get_tools(self : Server, w : @httpx.ResponseWriter) -> Unit {
  let tools = self.maria.agent.tools()
  let tools_json : Map[String, Json] = {}
  for name, tool in tools {
    tools_json[name] = { "enabled": tool.enabled() }
  }
  let response : Json = Json::object(tools_json)
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.stringify())
}

///|
async fn Server::get_system_prompt(
  self : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  let res : Json = match self.maria.agent.system_prompt() {
    Some(sys) => sys.to_json()
    None => Json::null()
  }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(res.stringify())
}

///|
/// Sends a generic external event to the agent.
///
/// Request body:
/// ```json
/// {
///   "type": "UserMessage" | "UserCancellation" | "Diagnostics",
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
    "UserCancellation" => queue.send(@event.ExternalEvent::UserCancellation)
    "UserMessage" => {
      guard json is { "message": String(message), .. } else {
        raise json_error(400, "BadRequest", {
          "error": "Missing 'message' field for UserMessage event",
        })
      }
      queue.send(@event.ExternalEvent::UserMessage(message))
    }
    "Diagnostics" => {
      guard json is { "diagnostics": String(diagnostics_jsonl), .. } else {
        raise json_error(400, "BadRequest", {
          "error": "Missing 'diagnostics' field for Diagnostics event",
        })
      }
      let diagnostics = @diagnostics.from_jsonl(diagnostics_jsonl)
      queue.send(@event.ExternalEvent::Diagnostics(diagnostics))
    }
    _ =>
      raise json_error(400, "BadRequest", {
        "error": "Unknown event type: \{event_type}. Expected 'UserMessage', 'UserCancellation', or 'Diagnostics'",
      })
  }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(Json::object({ "success": true }))
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
  self.maria.agent
  .external_events()
  .send(@event.ExternalEvent::Diagnostics(diagnostics))
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(
    Json::object({ "success": true, "count": diagnostics.length().to_json() }),
  )
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
  self.maria.agent
  .external_events()
  .send(@event.ExternalEvent::UserMessage(message))
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(Json::object({ "success": true }))
}

///|
/// Sends a cancellation event to the agent.
/// This will cause the agent to stop at the next poll point.
async fn Server::send_cancellation_event(
  self : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  self.maria.agent
  .external_events()
  .send(@event.ExternalEvent::UserCancellation)
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(Json::object({ "success": true }))
}
