///|
priv struct Server {
  maria : @maria.Maria
  uuid : @uuid.Generator
  broadcast : @broadcast.Broadcast[Json]
  message_queue : @aqueue.Queue[
    (@openai.ChatCompletionMessageParam, @aqueue.Queue[@uuid.Uuid?]),
  ]
  mut status : Status
  register : Register?
  serve : String
  port : Int
  tcp_server : @socket.TcpServer
}

///|
async fn Server::new(
  model? : String,
  log_level~ : @pino.Level,
  register? : Register,
  serve~ : String,
  port~ : Int,
  cwd? : String,
) -> Server {
  let broadcast : @broadcast.Broadcast[Json] = @broadcast.Broadcast::new()
  let uuid = @uuid.generator(@rand.chacha8())
  let logger = @pino.logger(
    "server",
    level=log_level,
    @pino.Transport::callback(event => {
      guard event is Object(event) else { return }
      event["id"] = uuid.v4().to_string().to_json()
      broadcast.put(Json::object(event))
    }),
  )
  let maria = @maria.Maria::new(model?, logger~, cwd?)
  let addr = try! @socket.Addr::parse("[::]:\{port}")
  let tcp_server = @socket.TcpServer::new(
    addr,
    dual_stack=true,
    reuse_addr=true,
  )
  let port = tcp_server.addr().port()
  Server::{
    maria,
    broadcast,
    message_queue: @aqueue.new(),
    status: Idle,
    uuid,
    register,
    serve,
    port,
    tcp_server,
  }
}

///|
async fn run_server(
  tcp_server : @socket.TcpServer,
  port~ : Int,
  register? : Register,
  f : async (@http.Request, @http.ServerConnection) -> Unit,
) -> Unit {
  if register is Some(register) {
    println("[INFO] (Server \{register.id}) Listening on port \{port}")
    println(
      "[INFO] (Server \{register.id}) Visit http://localhost:\{port}/ to access the server.",
    )
    let register_body : Json = { "id": register.id, "port": port }
    let (register_response, register_body) = @http.post(
      "http://\{register.host}/v1/task/register",
      register_body,
      port=register.port,
    )
    guard register_response.code is (200..=299) else {
      raise json_error(500, "InternalServerError", {
        "error": {
          "code": register_response.code,
          "message": register_response.reason,
          "metadata": { "body": register_body.text() },
        },
      })
    }
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
  tcp_server.run_forever((sock, _) => for {
    let conn = @http.ServerConnection::new(sock)
    try {
      let request = conn.read_request()
      println(
        "[INFO] (Server) Received request: \{request.meth} \{request.path}",
      )
      f(request, conn)
    } catch {
      HttpError(code~, reason~, body~) =>
        conn
        ..send_response(code, reason, extra_headers={
          "Content-Type": "application/json",
        })
        ..write(body)
        ..end_response()
      error => raise error
    }
  })
}

///|
async fn Server::serve(server : Server) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(
      () => while true {
        @async.with_task_group(group => {
          let (msg, idq) = server.message_queue.get()
          server.maria.agent.add_message(msg)
          group.spawn_bg(
            () => while true {
              let (msg, idq) = server.message_queue.get()
              let id = server.maria.agent.queue_message(msg)
              idq.put(Some(id))
            },
            no_wait=true,
          )
          idq.put(None)
          server.status = Busy
          defer {
            server.status = Idle
          }
          server.maria.agent.start() catch {
            error => {
              server.maria.logger.error("MariaFailed", {
                "error": {
                  "code": -1,
                  "message": error.to_string(),
                  "metadata": error,
                },
              })
              raise error
            }
          }
        })
      },
      allow_failure=true,
    )
    run_server(port=server.port, server.tcp_server, register?=server.register, (
      request,
      w,
    ) => match (request.meth, request.path) {
      (Options, _) => {
        w.send_response(204, "No Content", extra_headers={
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
          "Access-Control-Allow-Headers": "Content-Type",
        })
        w.end_response()
      }
      (Get, "/") => {
        let index_html = html_read_file(@path.join(server.serve, "index.html"))
        w.send_response(200, "OK", extra_headers={ "Content-Type": "text/html" })
        w.write(index_html)
        w.end_response()
      }
      (Get, "/v1/status") => {
        let response : Json = { "status": server.status }
        w.send_response(200, "OK", extra_headers={
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
          "Access-Control-Allow-Headers": "Content-Type",
        })
        w.write(response.stringify())
        w.end_response()
      }
      (Get, "/v1/queued-messages") => server.get_queued_messages(w)
      (Get, "/v1/events") => server.get_events(w)
      (Post, "/v1/message") => server.create_message(w)
      (Get, "/v1/moonbit/modules") => list_moonbit_modules(w)
      (Post, "/v1/moonbit/publish") => publish_moonbit_module(w)
      (Get, ['/', .. file]) if "\{server.serve}/\{file}" is path &&
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
        println("[DEBUG] Serving static file: \{path}")
        let content = html_read_file(path)
        w.send_response(200, "OK", extra_headers={
          "Content-Type": content_type,
        })
        w.write(content)
        w.end_response()
      }
      _ =>
        raise json_error(404, "NotFound", {
          "error": {
            "code": -1,
            "message": "Unknown endpoint: \{request.path}",
          },
        })
    })
  })
}

///|
async fn Server::get_events(self : Server, w : @http.ServerConnection) -> Unit {
  w.send_response(200, "OK", extra_headers={
    "Content-Type": "text/event-stream",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
    "Access-Control-Allow-Headers": "Content-Type",
    "X-Accel-Buffering": "no",
  })
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
            | "MariaFailed",
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
          queued_messages.push({ "id": id, "message": message.to_json() })
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
  w : @http.ServerConnection,
) -> Unit {
  let queued_messages : Array[Json] = []
  for m in self.maria.agent.queued_messages() {
    let (id, message) = m
    queued_messages.push({ "id": id, "message": message.to_json() })
  }
  let response : Json = queued_messages.to_json()
  w.send_response(200, "OK", extra_headers={
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
    "Access-Control-Allow-Headers": "Content-Type",
  })
  w.write(response.stringify())
  w.end_response()
}

///|
async fn Server::create_message(
  self : Server,
  conn : @http.ServerConnection,
) -> Unit {
  let body_data = conn.read_all().binary()
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
  let (id, queued) = {
    let idq = @aqueue.new()
    self.message_queue.put((message, idq))
    match idq.get() {
      Some(id) => (id, true)
      None => (self.uuid.v4(), false)
    }
  }
  let response : Json = { "id": id, "queued": queued }
  conn.send_response(200, "OK", extra_headers={
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
    "Access-Control-Allow-Headers": "Content-Type",
  })
  conn.write(response.stringify())
  conn.end_response()
}
