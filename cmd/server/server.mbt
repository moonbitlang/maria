///|
pub struct Server {
  priv maria : @maria.Maria
  priv broadcast : @broadcast.Broadcast[Json]
  priv message_queue : @aqueue.Queue[
    (@openai.ChatCompletionMessageParam, @aqueue.Queue[@uuid.Uuid]),
  ]
  priv mut task : @async.Task[Unit]?
  priv register : Register?
  priv serve : String
  priv port : Int
  priv http_server : @httpx.Server
  priv cwd : String
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
) -> Server {
  let broadcast : @broadcast.Broadcast[Json] = @broadcast.Broadcast::new()
  let uuid = @uuid.generator(@rand.chacha8())
  guard @model.load(cwd?=cwd.map(cwd => cwd), name?=model) is Some(model) else {
    fail("Failed to load model '\{model}' from cwd '\{cwd}'")
  }
  let maria = @maria.Maria::new(model~, cwd?)
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
  self.http_server.serve((r, w) => {
    println("[INFO] (Server) Received request: \{r.method_} \{r.path}")
    try {
      match (r.method_, r.path) {
        (Options, _) => {
          w.header().set("Access-Control-Allow-Origin", "*")
          w.header().set("Access-Control-Allow-Methods", "*")
          w.header().set("Access-Control-Allow-Headers", "*")
          w.write_header(204)
        }
        (Get, "/") => {
          let index_html = html_read_file(@path.join(self.serve, "index.html"))
          w.header().set("Content-Type", "text/html")
          w.write_header(200)
          w.write(index_html)
        }
        (Get, "/v1/status") => {
          let response : Json = { "status": self.status() }
          w.header().set("Content-Type", "application/json")
          w.header().set("Access-Control-Allow-Origin", "*")
          w.header().set("Access-Control-Allow-Methods", "*")
          w.header().set("Access-Control-Allow-Headers", "*")
          w.write_header(200)
          w.write(response.stringify())
        }
        (Post, "/v1/cancel") => self.cancel_maria(w)
        (Get, "/v1/queued-messages") => self.get_queued_messages(w)
        (Get, "/v1/events") => self.get_events(w)
        (Post, "/v1/message") => self.create_message(r, w)
        (Get, "/v1/moonbit/modules") => self.list_moonbit_modules(w)
        (Post, "/v1/moonbit/publish") => publish_moonbit_module(r, w)
        (Get, ['/', .. file]) if "\{self.serve}/\{file}" is path &&
          (try? @fsx.exists_as_file(path)) is Ok(true) => {
          let content_type = match @path.ext(path) {
            ".js" => "application/javascript"
            ".css" => "text/css"
            ".html" => "text/html"
            ".png" => "image/png"
            ".jpg" | ".jpeg" => "image/jpeg"
            ".gif" => "image/gif"
            _ => "application/octet-stream"
          }
          println("[DEBUG] (Server) Serving static file: \{path}")
          let content = html_read_file(path)
          w.header().set("Content-Type", content_type)
          w.write_header(200)
          w.write(content)
        }
        _ => {
          w.header().set("Content-Type", "application/json")
          w.header().set("Access-Control-Allow-Origin", "*")
          w.header().set("Access-Control-Allow-Methods", "*")
          w.header().set("Access-Control-Allow-Headers", "*")
          w.write_header(404)
          w.write(
            Json::object({
              "error": { "code": -1, "message": "Unknown endpoint: \{r.path}" },
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
  })
}

///|
async fn Server::start_maria(self : Server) -> Unit {
  while true {
    @async.with_task_group(group => {
      let (msg, idq) = self.message_queue.get()
      let msg = msg.to_ai_message()
      let id = self.maria.agent.queue_message(msg)
      group.spawn_bg(
        () => while true {
          let (msg, idq) = self.message_queue.get()
          let msg = msg.to_ai_message()
          let id = self.maria.agent.queue_message(msg)
          idq.put(id)
        },
        no_wait=true,
      )
      idq.put(id)
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
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(Json::object({}))
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
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.write_header(200)
  w.write("event: maria.queued_messages.synchronized\n")
  let queued_messages : Array[Json] = []
  for m in self.maria.agent.queued_messages() {
    let (id, message) = m
    queued_messages.push({
      "id": id,
      "message": @openai.ChatCompletionMessageParam::from_ai_message(message).to_json(),
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
      guard event
        is Object(
          {
            "msg": "MessageAdded"
            | "MessageQueued"
            | "MessageUnqueued"
            | "PreConversation"
            | "RequestCompleted"
            | "PostToolCall"
            | "PostConversation"
            | "MariaFailed"
            | "MariaCancelled",
            ..
          } as event
        ) else {
        continue
      }
      // Skip over tool events (subagent events)
      if event is { "tool": { "name": String(_), "id": _, .. }, .. } {
        continue
      }
      let event = Json::object(event)
      w.write("event: maria\n")
      w.write("data: \{event.stringify()}\n\n")
      w.flush()
      if event is { "msg": "MessageQueued" | "MessageUnqueued", .. } {
        w.write("event: maria.queued_messages.synchronized\n")
        let queued_messages : Array[Json] = []
        for m in self.maria.agent.queued_messages() {
          let (id, message) = m
          queued_messages.push({
            "id": id,
            "message": @openai.ChatCompletionMessageParam::from_ai_message(
              message,
            ).to_json(),
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
    let (id, message) = m
    queued_messages.push({
      "id": id,
      "message": @openai.ChatCompletionMessageParam::from_ai_message(message).to_json(),
    })
  }
  let response : Json = queued_messages.to_json()
  w.header().set("Content-Type", "application/json")
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.write_header(200)
  w.write(response.stringify())
}

///|
async fn Server::create_message(
  self : Server,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let body_data = r.body.read_all().binary()
  let body_text : String = @encoding/utf8.decode(body_data) catch {
    // TODO(upstream): impl Show for @encoding/utf8.Malformed
    @encoding/utf8.Malformed(bytes) =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid UTF-8 in request body: \{bytes}",
        },
      })
  }
  let body_json = @json.parse(body_text) catch {
    error =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid JSON in request body: \{error}",
        },
      })
  }
  guard body_json is { "message": message, .. } else {
    raise json_error(400, "BadRequest", {
      "error": {
        "code": -1,
        "message": "Missing 'message' field in request body",
      },
    })
  }
  let message : @openai.ChatCompletionMessageParam = @json.from_json(message) catch {
    @json.JsonDecodeError(_) as error =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid 'message' field: \{error}",
          "metadata": { "message": message },
        },
      })
  }
  let id = {
    let idq = @aqueue.new(kind=Unbounded)
    self.message_queue.put((message, idq))
    idq.get()
  }
  let response : Json = { "id": id, "queued": true }
  w.header().set("Content-Type", "application/json")
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.write_header(200)
  w.write(response.stringify())
}
