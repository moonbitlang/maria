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
priv struct Server {
  name : String
  id : @uuid.Uuid
  cwd : String
  port : Int
}

///|
priv struct Daemon {
  models : @model.Loader
  uuid : @uuid.Generator
  process : @spawn.Manager
  by_cwd : Map[String, Server]
  by_id : Map[@uuid.Uuid, Server]
}

///|
async fn Daemon::start(self : Daemon) -> Unit {
  self.process.start()
}

///|
async fn run_server(
  port~ : Int,
  f : async (@http.Request, @http.ServerConnection) -> Unit,
) -> Unit {
  let addr = try! @socket.Addr::parse("[::]:\{port}")
  println("[INFO] Starting HTTP server on port \{port}...")
  println("[INFO] Visit http://localhost:\{port}/")
  @http.run_server(addr, (conn, _) => for {
    try {
      let request = conn.read_request()
      println("[INFO] Received request: \{request.meth} \{request.path}")
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
async fn find_available_port(start_port : Int) -> Int {
  println("[INFO] Finding available port starting from \{start_port}...")
  for port in start_port..<(start_port + 1000) {
    let addr = @socket.Addr::parse("[::]:\{port}")
    let server = @socket.TcpServer::new(addr) catch {
      error => {
        println("[DEBUG] Port \{port} is not available: \{error}")
        continue port + 1
      }
    }
    server.close()
    return port
  } else {
    fail(
      "No available port found in range \{start_port} to \{start_port + 1000}",
    )
  }
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
async fn main {
  let args = @os.args()
  let mut port = 8090
  let mut serve = @os.cwd()
  let mut exec_path = None
  loop args[1:] {
    ["-p" | "--port", p, .. args] => {
      port = @strconv.parse_int(p)
      continue args
    }
    ["-s" | "--serve", s, .. args] => {
      serve = s
      continue args
    }
    [e, .. args] => {
      exec_path = if @path.is_absolute(e) {
        Some(e)
      } else {
        Some(@path.join(@os.cwd(), e))
      }
      continue args
    }
    [] => break
  }
  guard exec_path is Some(exec_path) else {
    fail("Expected exec path as the first argument")
  }
  if !@fsx.exists(exec_path) {
    fail("Exec path does not exist: \{exec_path}")
  }
  let logger = @pino.logger("daemon", @pino.Transport::console())
  let daemon = Daemon::{
    models: @model.Loader::new(home=@os.home(), cwd=@os.cwd(), logger~),
    uuid: @uuid.generator(@rand.chacha8()),
    process: @spawn.Manager::new(cwd=@os.cwd()),
    by_cwd: {},
    by_id: {},
  }
  @async.with_task_group(group => {
    group.spawn_bg(() => daemon.start())
    run_server(port~, (request, conn) => {
      let paths = request.path.split("/").collect()
      println("[DEBUG] Handling request paths: \{paths}")
      match (request.meth, paths) {
        // GET /
        (Get, ["", ""]) => {
          let index_html = html_read_file(@path.join(serve, "index.html"))
          conn
          ..send_response(200, "OK", extra_headers={
            "Content-Type": "text/html",
          })
          ..write(index_html)
          ..end_response()
        }
        (Get, ["", "v1", "models"]) => {
          let models : Array[Json] = []
          for model in daemon.models.models() {
            models.push({ "name": model.name })
          }
          let response : Json = { "models": models }
          conn
          ..send_response(200, "OK", extra_headers={
            "Content-Type": "application/json",
          })
          ..write(response.stringify())
          ..end_response()
        }
        (Get, ["", "v1", "tasks"]) => {
          let tasks : Array[Json] = []
          for _, server in daemon.by_cwd {
            tasks.push({
              "name": server.name,
              "id": server.id.to_string(),
              "cwd": server.cwd,
              "port": server.port,
            })
          }
          let response : Json = { "tasks": tasks }
          conn
          ..send_response(200, "OK", extra_headers={
            "Content-Type": "application/json",
          })
          ..write(response.stringify())
          ..end_response()
        }
        (Post, ["", "v1", "task"]) => {
          let request_bytes = conn.read_all().binary()
          println("[DEBUG] Request body bytes: \{request_bytes}")
          let request_text = @encoding/utf8.decode(request_bytes) catch {
            @encoding/utf8.Malformed(bytes) =>
              raise text_error(
                400,
                "Bad Request",
                "Invalid UTF-8 in request body: \{bytes}",
              )
          }
          println("[DEBUG] Request body text: \{request_text}")
          let request_json = @json.parse(request_text) catch {
            error =>
              raise text_error(
                400,
                "Bad Request",
                "Invalid JSON in request body: \{error}",
              )
          }
          println(
            "[DEBUG] Request body JSON: \{request_json.stringify(indent=2)}",
          )
          guard request_json
            is {
              "name": String(name),
              "model": String(model),
              "cwd": String(cwd),
              ..
            } else {
            raise text_error(
              400, "Bad Request", "Missing required fields in request body",
            )
          }
          if daemon.by_cwd.get(cwd) is Some(server) {
            raise json_error(409, "Conflict", {
              "task": {
                "name": server.name,
                "id": server.id.to_string(),
                "cwd": server.cwd,
                "port": server.port,
              },
            })
          }
          let port = find_available_port(9000)
          println(
            "[INFO] Spawning task '\{name}' at '\{cwd}' on port \{port}...",
          )
          println("[DEBUG] Exec path: \{exec_path}, Model: \{model}")
          let process = daemon.process.spawn(
            exec_path,
            ["--model", model, "--port", port.to_string()],
            cwd~,
          )
          println("[INFO] Spawned task process with PID \{process.pid}")
          let server = Server::{ name, id: daemon.uuid.v4(), cwd, port }
          group.spawn_bg(() => {
            let exit_code = process.wait()
            if exit_code != 0 {
              println("[ERROR] task process exited with code \{exit_code}")
            }
            daemon.by_cwd.remove(cwd)
            daemon.by_id.remove(server.id)
          })
          daemon.by_cwd[cwd] = server
          daemon.by_id[server.id] = server
          conn.send_response(201, "Created")
          let body : Json = {
            "task": {
              "name": server.name,
              "id": server.id.to_string(),
              "cwd": server.cwd,
              "port": server.port,
            },
          }
          conn.write(body)
          conn.flush()
          conn.end_response()
        }
        (Get, ["", "v1", "task", id, "events"]) => {
          guard daemon.by_id.get(
              @uuid.parse(id) catch {
                _ =>
                  raise json_error(400, "Bad Request", {
                    "error": { "code": -1, "message": "Invalid UUID: \{id}" },
                  })
              },
            )
            is Some(server) else {
            raise json_error(404, "Not Found", {
              "error": { "code": -1, "message": "Task not found: \{id}" },
            })
          }
          println("[INFO] Streaming events for task \{id}...")
          let (response, client) = @http.get_stream(
            "http://localhost/v1/events",
            headers=request.headers,
            port=server.port,
            body=conn.read_all(),
          )
          println(
            "[DEBUG] Received response: \{response.code} \{response.reason}",
          )
          conn.send_response(response.code, response.reason, extra_headers={
            "Content-Type": "text/event-stream",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
            "Access-Control-Allow-Headers": "Content-Type",
          })
          println("[DEBUG] Streaming response body...")
          conn.write_reader(client)
          println("[DEBUG] Finished streaming response body.")
          conn.end_response()
        }
        (Get, ["", "v1", "task", id, "moonbit", "modules"]) => {
          guard daemon.by_id.get(
              @uuid.parse(id) catch {
                _ =>
                  raise json_error(400, "Bad Request", {
                    "error": { "code": -1, "message": "Invalid UUID: \{id}" },
                  })
              },
            )
            is Some(server) else {
            raise json_error(404, "Not Found", {
              "error": { "code": -1, "message": "Task not found: \{id}" },
            })
          }
          println("[INFO] Forwarding moonbit modules request to task \{id}...")
          let (response, response_body) = @http.get(
            "http://localhost/v1/moonbit/modules",
            headers=request.headers,
            port=server.port,
            body=conn.read_all(),
          )
          conn.send_response(response.code, response.reason, extra_headers={
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
            "Access-Control-Allow-Headers": "Content-Type",
          })
          conn.write(response_body)
          conn.end_response()
        }
        (Post, ["", "v1", "moonbit", "publish"]) => {
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
        (Post, ["", "v1", "task", id, "message"]) => {
          guard daemon.by_id.get(
              @uuid.parse(id) catch {
                _ =>
                  raise json_error(400, "Bad Request", {
                    "error": { "code": -1, "message": "Invalid UUID: \{id}" },
                  })
              },
            )
            is Some(server) else {
            raise json_error(404, "Not Found", {
              "error": { "code": -1, "message": "Task not found: \{id}" },
            })
          }
          println("[INFO] Forwarding message to task \{id}...")
          let (response, response_body) = @http.post(
            "http://localhost/v1/message",
            headers=request.headers,
            port=server.port,
            conn.read_all(),
          )
          conn.send_response(response.code, response.reason, extra_headers={
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
            "Access-Control-Allow-Headers": "Content-Type",
          })
          conn.write(response_body)
          conn.end_response()
        }
        (Get, ["", .. file]) if @path.join(serve, file.join("/")) is path &&
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
          conn
          ..send_response(200, "OK", extra_headers={
            "Content-Type": content_type,
          })
          ..write(content)
          ..end_response()
        }
        _ =>
          raise json_error(404, "NotFound", {
            "error": {
              "code": -1,
              "message": "Unknown endpoint: \{request.path}",
              "metadata": {
                "method": request.meth.to_string(),
                "path": request.path,
              },
            },
          })
      }
    })
  })
}
