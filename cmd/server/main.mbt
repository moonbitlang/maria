///|
priv suberror HttpError {
  HttpError(code~ : Int, reason~ : String, body~ : String)
}

///|
fn json_error(code : Int, reason : String, body : Json) -> HttpError {
  HttpError(code~, reason~, body=body.stringify())
}

///|
fn text_error(code : Int, reason : String, body : String) -> HttpError {
  HttpError(code~, reason~, body~)
}

///|
priv struct Register {
  host : String
  port : Int
  id : String
}

///|
async fn run_server(
  port~ : Int,
  register? : Register,
  f : async (@http.Request, @http.ServerConnection) -> Unit,
) -> Unit {
  let addr = try! @socket.Addr::parse("[::]:\{port}")
  let server = @socket.TcpServer::new(addr, dual_stack=true)
  let port = server.addr().port()
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
  server.run_forever((sock, _) => for {
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
async fn html_read_file(path : String) -> String {
  @fsx.read_file(path) catch {
    @os_error.OSError(_) as os_error if os_error.is_ENOENT() =>
      raise text_error(404, "NotFound", "<h1>404 Not Found</h1>")
    error => raise error
  }
}

///|
async fn collect_modules(
  directory : String,
  modules : Array[@moon.Module],
) -> Unit {
  let moon_mod_json = @path.join(directory, "moon.mod.json")
  if @fsx.exists(moon_mod_json) {
    modules.push(@moon.Module::load(directory))
  } else {
    let entries = @fsx.list_directory(directory)
    for entry in entries {
      if entry.kind is Directory {
        collect_modules(entry.path, modules)
      }
    }
  }
}

///|
priv struct Server {
  broadcast : @broadcast.Broadcast[Json]
  message_queue : @aqueue.Queue[@openai.ChatCompletionMessageParam]
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
    let hist : Array[Json] = hist.filter(e => e
      is {
        "msg": "MessageAdded"
        | "PreConversation"
        | "RequestCompleted"
        | "PostToolCall"
        | "PostConversation"
        | "MariaFailed",
        ..
      } &&
      !(e is { "tool": { "name": String(_), "id": _, .. }, .. }))
    w.write("event: maria.history\n")
    w.write("data: \{hist.to_json().stringify()}\n\n")
    w.flush()
    for {
      let event = chan.get()
      guard event
        is {
          "msg": "MessageAdded"
          | "PreConversation"
          | "RequestCompleted"
          | "PostToolCall"
          | "PostConversation"
          | "MariaFailed",
          ..
        } else {
        continue
      }
      // Skip over tool events (subagent events)
      if event is { "tool": { "name": String(_), "id": _, .. }, .. } {
        continue
      }
      w.write("event: maria\n")
      w.write("data: \{event.stringify()}\n\n")
      w.flush()
    }
  })
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
  self.message_queue.put(message)
  let response : Json = {}
  conn
  ..send_response(200, "OK", extra_headers={
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
    "Access-Control-Allow-Headers": "Content-Type",
  })
  ..write(response.stringify())
  ..end_response()
}

///|
async fn list_moonbit_modules(conn : @http.ServerConnection) -> Unit {
  let modules = []
  collect_modules(@os.cwd(), modules)
  let modules_json : Array[Json] = []
  for mod in modules {
    modules_json.push({
      "path": mod.path,
      "name": mod.name,
      "version": mod.version,
      "description": mod.description,
    })
  }
  let response : Json = { "modules": modules_json }
  conn
  ..send_response(200, "OK", extra_headers={
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
    "Access-Control-Allow-Headers": "Content-Type",
  })
  ..write(response.stringify())
  ..end_response()
}

///|
async fn publish_moonbit_module(conn : @http.ServerConnection) -> Unit {
  let request = conn.read_all().binary()
  let request_text : String = @encoding/utf8.decode(request) catch {
    // TODO(upstream): impl Show for @encoding/utf8.Malformed
    @encoding/utf8.Malformed(bytes) =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid UTF-8 in request body: \{bytes}",
        },
      })
  }
  let request_json = @json.parse(request_text) catch {
    error =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid JSON in request body: \{error}",
        },
      })
  }
  guard request_json is { "module": { "path": String(path), .. }, .. } else {
    raise json_error(400, "BadRequest", {
      "error": {
        "code": -1,
        "message": "Missing 'module.path' field in request body",
      },
    })
  }
  let process = @spawn.spawn("moon", ["publish"], cwd=path) catch {
    error =>
      raise json_error(500, "InternalServerError", {
        "error": {
          "code": -1,
          "message": "Failed to spawn 'moon publish' for '\{path}': \{error}",
        },
      })
  }
  let module_ = @moon.Module::load(path) catch {
    error =>
      raise json_error(404, "NotFound", {
        "error": {
          "code": -1,
          "message": "No MoonBit module found in path '\{path}': \{error}",
        },
      })
  }
  if process.status == 0 {
    let response : Json = {
      "module": {
        "path": path,
        "name": module_.name,
        "version": module_.version,
        "description": module_.description,
      },
      "process": {
        "status": process.status,
        "stdout": process.stdout,
        "stderr": process.stderr,
      },
    }
    conn
    ..send_response(201, "Created", extra_headers={
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
      "Access-Control-Allow-Headers": "Content-Type",
    })
    ..write(response.stringify())
    ..end_response()
  } else {
    let response : Json = {
      "error": {
        "code": -1,
        "message": "Failed to publish module at '\{path}'",
        "metadata": {
          "module": {
            "path": path,
            "name": module_.name,
            "version": module_.version,
            "description": module_.description,
          },
          "process": {
            "status": process.status,
            "stdout": process.stdout,
            "stderr": process.stderr,
          },
        },
      },
    }
    conn
    ..send_response(500, "InternalServerError", extra_headers={
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
      "Access-Control-Allow-Headers": "Content-Type",
    })
    ..write(response.stringify())
    ..end_response()
  }
}

///|
pub(all) enum Status {
  Idle
  Busy
} derive(ToJson, @json.FromJson)

///|
test "Status::ToJson" {
  @json.inspect(Idle, content="Idle")
  @json.inspect(Busy, content="Busy")
}

///|
test "Status::FromJson" {
  @json.inspect(@json.from_json("Idle") is Idle, content=true)
  @json.inspect(@json.from_json("Busy") is Busy, content=true)
}

///|
async fn main {
  let args = @os.args()
  let mut model = None
  let mut port = 0
  let mut serve = @os.cwd()
  let mut log_level = @pino.Info
  let mut register_host = None
  let mut register_port = None
  let mut register_id = None
  loop args[1:] {
    ["-m" | "--model", m, .. args] =>
      if m.has_prefix("-") {
        fail("Expected model name after \{args[0]}")
      } else {
        model = Some(m)
        continue args
      }
    ["-p" | "--port", p, .. args] => {
      port = @strconv.parse_int(p)
      continue args
    }
    ["--register-host", d, .. args] =>
      if d.has_prefix("-") {
        fail("Expected daemon host after \{args[0]}")
      } else {
        register_host = Some(d)
        continue args
      }
    ["--register-port", dp, .. args] => {
      register_port = Some(@strconv.parse_int(dp))
      continue args
    }
    ["--register-id", du, .. args] =>
      if du.has_prefix("-") {
        fail("Expected register id after \{args[0]}")
      } else {
        register_id = Some(du)
        continue args
      }
    ["--serve", s, .. args] =>
      if s.has_prefix("-") {
        fail("Expected serve path after \{args[0]}")
      } else {
        serve = s
        continue args
      }
    ["--log-level", level, .. args] => {
      log_level = match level.to_lower() {
        "debug" => @pino.Debug
        "info" => @pino.Info
        "warn" => @pino.Warn
        "error" => @pino.Error
        _ => fail("Unknown log level: \{level}")
      }
      continue args
    }
    [unknown, ..] => {
      let error : Json = {
        "error": { "code": -1, "message": "Unknown argument: \{unknown}" },
      }
      println(error.stringify())
    }
    [] => break
  }
  let register = match (register_host, register_port, register_id) {
    (Some(host), Some(port), Some(id)) => Some({ host, port, id })
    (None, None, None) => None
    _ =>
      fail(
        "--register-host, --register-port, and --register-id must be provided together",
      )
  }
  let broadcast = @broadcast.Broadcast::new()
  let logger = @pino.logger(
    "server",
    level=log_level,
    @pino.Transport::callback(event => broadcast.put(event)),
  )
  let message_queue = @aqueue.new()
  let server = Server::{ broadcast, message_queue }
  let maria = @maria.Maria::new(model?, logger~)
  let mut status = Idle
  @async.with_task_group(group => {
    group.spawn_bg(
      () => while true {
        let message = message_queue.get()
        maria.agent.add_message(message)
        status = Busy
        defer {
          status = Idle
        }
        maria.agent.start() catch {
          error => {
            logger.error("MariaFailed", {
              "error": {
                "code": -1,
                "message": error.to_string(),
                "metadata": error,
              },
            })
            raise error
          }
        }
      },
      allow_failure=true,
    )
    run_server(port~, register?, (request, w) => match
      (request.meth, request.path) {
      (Options, _) => {
        w.send_response(204, "No Content", extra_headers={
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
          "Access-Control-Allow-Headers": "Content-Type",
        })
        w.end_response()
      }
      (Get, "/") => {
        let index_html = html_read_file(@path.join(serve, "index.html"))
        w.send_response(200, "OK", extra_headers={ "Content-Type": "text/html" })
        w.write(index_html)
        w.end_response()
      }
      (Get, "/v1/status") => {
        let response : Json = { "status": status }
        w.send_response(200, "OK", extra_headers={
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
          "Access-Control-Allow-Headers": "Content-Type",
        })
        w.write(response.stringify())
        w.end_response()
      }
      (Get, "/v1/events") => server.get_events(w)
      (Post, "/v1/message") => server.create_message(w)
      (Get, "/v1/moonbit/modules") => list_moonbit_modules(w)
      (Post, "/v1/moonbit/publish") => publish_moonbit_module(w)
      (Get, ['/', .. file]) if "\{serve}/\{file}" is path &&
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
