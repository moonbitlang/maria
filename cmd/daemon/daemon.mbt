///|
priv struct Daemon {
  clock : &@clock.Clock
  models : @model.Loader
  uuid : @uuid.Generator
  process : @spawn.Manager
  by_cwd : Map[String, Task]
  by_id : Map[@uuid.Uuid, Task]
  rqs : Map[String, @aqueue.Queue[Int]]
  exec_path : String
  tcp_server : @socket.TcpServer
  port : Int
  events : @broadcast.Broadcast[Event]
  serve : String
}

///|
priv enum Event {
  StatusChange(@uuid.Uuid)
}

///|
async fn Daemon::get_events(self : Daemon, w : @http.ServerConnection) -> Unit {
  w.send_response(200, "OK", extra_headers={
    "Content-Type": "text/event-stream",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
    "Access-Control-Allow-Headers": "Content-Type",
    "X-Accel-Buffering": "no",
  })
  let tasks : Array[Task] = self.by_cwd.values().collect()
  w.write("event: daemon.tasks.synchronized\n")
  let data : Json = { "tasks": tasks }
  w.write("data: \{data.stringify()}\n\n")
  w.flush()
  self.events.listen((_, chan) => loop chan.get() {
    StatusChange(id) => {
      let data : Json = { "task": self.by_id[id] }
      w.write("event: daemon.task.changed\n")
      w.write("data: \{data.stringify()}\n\n")
      w.flush()
      continue chan.get()
    }
  })
}

///|
async fn Daemon::listen_for_status_change(self : Daemon, task : Task) -> Unit {
  println(
    "[INFO] (Daemon) Listening for status changes from task \{task.id}...",
  )
  let (er, eb) = @http.get_stream("http://localhost/v1/events", port=task.port)
  defer eb.close()
  guard er.code is (200..=299) else {
    raise json_error(500, "Internal Server Error", {
      "error": {
        "code": er.code,
        "message": "Failed to connect to task event stream: \{er.code} \{er.reason}",
        "metadata": {
          "code": er.code,
          "reason": er.reason,
          "body": eb.read_all().json(),
        },
      },
    })
  }
  println("[INFO] (Daemon) Connected to task \{task.id} event stream.")
  loop eb.read_until("\n") {
    None => break
    Some(line) => {
      guard line is [.. "data: ", .. data] else { continue eb.read_until("\n") }
      let json = @json.parse(data)
      match json {
        { "msg": "PostConversation", .. } => {
          println("[INFO] (Daemon) Task \{task.id} is now idle.")
          task.status = Idle
          self.events.put(StatusChange(task.id))
        }
        { "msg": "PreConversation", .. } => {
          println("[INFO] (Daemon) Task \{task.id} is now busy.")
          task.status = Busy
          self.events.put(StatusChange(task.id))
        }
        _ => ()
      }
      continue eb.read_until("\n")
    }
  }
}

///|
priv struct Register {
  id : String
  port : Int
}

///|
async fn Daemon::create_task(
  self : Daemon,
  group~ : @async.TaskGroup[Unit],
  w : @http.ServerConnection,
) -> Unit {
  guard {
      let bytes = w.read_all().binary()
      let text = @encoding/utf8.decode(bytes) catch {
        @encoding/utf8.Malformed(bytes) =>
          raise json_error(
            400,
            "Bad Request",
            "Invalid UTF-8 in request body: \{bytes}",
          )
      }
      @json.parse(text) catch {
        error =>
          raise json_error(
            400,
            "Bad Request",
            "Invalid JSON in request body: \{error}",
          )
      }
    }
    is {
      "name"? : name,
      "model"? : model_name,
      "cwd"? : cwd,
      "message"? : message,
      ..
    } else {
    raise json_error(400, "Bad Request", {
      "error": {
        "code": -1,
        "message": "Missing required fields 'prompt' or 'model'",
      },
    })
  }
  let model_name : String? = model_name.map(model_name => @json.from_json(
    model_name,
  )) catch {
    error =>
      raise json_error(400, "Bad Request", {
        "error": { "code": -1, "message": "Invalid 'model' field: \{error}" },
      })
  }
  guard self.models.get_model(name?=model_name) is Some(model) else {
    raise json_error(404, "Not Found", {
      "error": { "code": -1, "message": "Model not found: \{model_name}" },
    })
  }
  let name : String? = name.map(name => @json.from_json(name)) catch {
    error =>
      raise json_error(400, "Bad Request", {
        "error": { "code": -1, "message": "Invalid 'name' field: \{error}" },
      })
  }
  let message : @openai.ChatCompletionMessageParam? = message.map(message => @json.from_json(
    message,
  )) catch {
    error =>
      raise json_error(400, "Bad Request", {
        "error": { "code": -1, "message": "Invalid 'message' field: \{error}" },
      })
  }
  let cwd = if cwd is Some(cwd) {
    if cwd is String(cwd) {
      let exists = @fsx.exists(cwd) catch {
        error =>
          raise json_error(500, "Internal Server Error", {
            "error": {
              "code": -1,
              "message": "Failed to check existence of 'cwd' path: \{error}",
              "metadata": { "cwd": cwd, "error": error.to_json() },
            },
          })
      }
      if !exists {
        raise json_error(404, "Not Found", {
          "error": {
            "code": -1,
            "message": "Specified 'cwd' path does not exist: \{cwd}",
            "metadata": { "cwd": cwd },
          },
        })
      }
      cwd
    } else {
      raise json_error(400, "Bad Request", {
        "error": {
          "code": -1,
          "message": "Invalid 'cwd' field: expected string",
        },
      })
    }
  } else {
    @fsx.mkdtemp(@path.join(@os.tmpdir(), "maria-server-task-XXXXXX")) catch {
      error =>
        raise json_error(500, "Internal Server Error", {
          "error": {
            "code": -1,
            "message": "Failed to create temporary working directory: \{error}",
          },
        })
    }
  }
  if self.by_cwd.get(cwd) is Some(task) {
    raise json_error(409, "Conflict", { "task": task })
  }
  let id = self.uuid.v4()
  let args = [
    "--model",
    model.name,
    "--port",
    "0",
    "--register-id",
    id.to_string(),
    "--register-host",
    "localhost",
    "--register-port",
    self.port.to_string(),
  ]
  let process = self.process.spawn(self.exec_path, args, cwd~) catch {
    error =>
      raise json_error(500, "Internal Server Error", {
        "error": {
          "code": -1,
          "message": "Failed to spawn task process: \{error}",
          "metadata": { "cwd": cwd, "exec_path": self.exec_path, "args": args },
        },
      })
  }
  println(
    "[INFO] (Daemon) Spawned task process with PID \{process.pid} and ID \{id} at '\{cwd}'",
  )
  let rq = @aqueue.Queue::new()
  self.rqs[id.to_string()] = rq
  let task_port = @async.with_timeout(300_000, () => rq.get()) catch {
    @async.TimeoutError => {
      println(
        "[ERROR] (Daemon) Timed out waiting for task to register after 5 minutes",
      )
      raise json_error(500, "Internal Server Error", {
        "error": {
          "code": -1,
          "message": "Timed out waiting for task to register",
        },
      })
    }
    error => raise error
  }
  println(
    "[INFO] (Daemon) Received registration from task '\{id}' on port \{task_port}",
  )
  let created = self.clock.now() / 1_000
  let task = Task::{ name, id, cwd, port: task_port, status: Idle, created }
  // FIXME: The daemon does not ends anyway, so this cleanup code is never run.
  group.spawn_bg(() => {
    let exit_code = process.wait()
    if exit_code != 0 {
      println("[ERROR] (Daemon) server process exited with code \{exit_code}")
    }
    self.by_cwd.remove(cwd)
    self.by_id.remove(task.id)
  })
  self.by_cwd[cwd] = task
  self.by_id[task.id] = task
  // FIXME: The daemon does not ends anyway, so the `no_wait` option is
  // unnecessary.
  group.spawn_bg(() => self.listen_for_status_change(task), no_wait=true)
  if message is Some(message) {
    println("[INFO] (Daemon) Write initial messages to task '\{id}'...")
    let (r, b) = @http.post(
      "http://localhost/v1/message",
      ({ "message": message } : Json),
      port=task_port,
    )
    guard r.code is (200..=299) else {
      raise json_error(500, "Internal Server Error", {
        "error": {
          "code": r.code,
          "message": "Failed to send initial message to task: \{r.code} \{r.reason}",
          "metadata": { "code": r.code, "reason": r.reason, "body": b.json() },
        },
      })
    }
  }
  w.send_response(201, "Created", extra_headers={
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
    "Access-Control-Allow-Headers": "Content-Type",
  })
  let body : Json = { "task": task }
  w.write(body)
  w.flush()
  w.end_response()
}

///|
async fn Daemon::list_models(
  self : Daemon,
  conn : @http.ServerConnection,
) -> Unit {
  let models : Array[Json] = []
  for model in self.models.models() {
    models.push({ "name": model.name })
  }
  let response : Json = { "models": models }
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
async fn Daemon::register_task(
  self : Daemon,
  conn : @http.ServerConnection,
) -> Unit {
  let request_bytes = conn.read_all().binary()
  let request_text = @encoding/utf8.decode(request_bytes) catch {
    @encoding/utf8.Malformed(bytes) =>
      raise json_error(
        400,
        "Bad Request",
        "Invalid UTF-8 in request body: \{bytes}",
      )
  }
  let request_json = @json.parse(request_text) catch {
    error =>
      raise json_error(
        400,
        "Bad Request",
        "Invalid JSON in request body: \{error}",
      )
  }
  guard request_json is { "id": id, "port": port, .. } else {
    raise json_error(400, "Bad Request", {
      "error": {
        "code": -1,
        "message": "Missing required fields 'id' or 'port'",
      },
    })
  }
  let id : String = @json.from_json(id) catch {
    error =>
      raise json_error(400, "Bad Request", {
        "error": { "code": -1, "message": "Invalid 'id' field: \{error}" },
      })
  }
  let port : Int = @json.from_json(port) catch {
    error =>
      raise json_error(400, "Bad Request", {
        "error": { "code": -1, "message": "Invalid 'port' field: \{error}" },
      })
  }
  let register : Register = { id, port }
  println("[INFO] Registered task '\{register.id}' on port \{register.port}")
  self.rqs[id].put(register.port)
  conn.send_response(200, "OK", extra_headers={
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
    "Access-Control-Allow-Headers": "Content-Type",
  })
  conn.end_response()
}

///|
async fn Daemon::list_tasks(self : Daemon, w : @http.ServerConnection) -> Unit {
  let tasks = self.by_cwd.values().collect()
  let response : Json = { "tasks": tasks }
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
async fn Daemon::get_task(
  self : Daemon,
  id : StringView,
  conn : @http.ServerConnection,
) -> Unit {
  guard self.by_id.get(
      @uuid.parse(id) catch {
        _ =>
          raise json_error(400, "Bad Request", {
            "error": { "code": -1, "message": "Invalid UUID: \{id}" },
          })
      },
    )
    is Some(task) else {
    raise json_error(404, "Not Found", {
      "error": { "code": -1, "message": "Task not found: \{id}" },
    })
  }
  let task_json = task.to_json_object()
  task_json["queued_messages"] = task.queued_messages().to_json()
  let response : Json = { "task": task_json }
  conn.send_response(200, "OK", extra_headers={
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
    "Access-Control-Allow-Headers": "Content-Type",
  })
  conn.write(response.stringify())
  conn.end_response()
}

///|
async fn Daemon::get_task_events(
  self : Daemon,
  id : StringView,
  w : @http.ServerConnection,
) -> Unit {
  guard self.by_id.get(
      @uuid.parse(id) catch {
        _ =>
          raise json_error(400, "Bad Request", {
            "error": { "code": -1, "message": "Invalid UUID: \{id}" },
          })
      },
    )
    is Some(task) else {
    raise json_error(404, "Not Found", {
      "error": { "code": -1, "message": "Task not found: \{id}" },
    })
  }
  let (response, client) = @http.get_stream(
    "http://localhost/v1/events",
    port=task.port,
    body=w.read_all(),
  )
  w.send_response(response.code, response.reason, extra_headers={
    "Content-Type": "text/event-stream",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
    "Access-Control-Allow-Headers": "Content-Type",
    "X-Accel-Buffering": "no",
  })
  w.write_reader(client)
  w.end_response()
}

///|
async fn Daemon::list_moonbit_modules(
  self : Daemon,
  id : StringView,
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Unit {
  guard self.by_id.get(
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

///|
async fn Daemon::create_task_message(
  self : Daemon,
  id : StringView,
  conn : @http.ServerConnection,
) -> Unit {
  guard self.by_id.get(
      @uuid.parse(id) catch {
        _ =>
          raise json_error(400, "Bad Request", {
            "error": { "code": -1, "message": "Invalid UUID: \{id}" },
          })
      },
    )
    is Some(task) else {
    raise json_error(404, "Not Found", {
      "error": { "code": -1, "message": "Task not found: \{id}" },
    })
  }
  let (response, response_body) = @http.post(
    "http://localhost/v1/message",
    port=task.port,
    conn.read_all(),
  )
  println(
    "[INFO] (Daemon) Forwarded message to task \{id} @ localhost:\{task.port}",
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

///|
async fn Daemon::new(
  uuid? : @uuid.Generator,
  exec_path~ : String,
  port~ : Int,
  serve~ : String,
  cwd? : StringView,
) -> Daemon {
  // Validate exec_path points to an existing file.
  if !@fsx.exists(exec_path) {
    fail("Exec path does not exist: \{exec_path}")
  }
  let exec_path = @fsx.resolve(exec_path) catch {
    error => fail("Failed to resolve exec path '\{exec_path}': \{error}")
  }
  // Create TCP server.
  let addr = try! @socket.Addr::parse("[::]:\{port}")
  let tcp_server = @socket.TcpServer::new(
    addr,
    dual_stack=true,
    reuse_addr=true,
  )
  let port = tcp_server.addr().port()
  println("[INFO] Starting HTTP server on port \{port}...")
  println("[INFO] Visit http://localhost:\{port}/")
  let logger = @pino.logger("daemon", @pino.Transport::console())
  let uuid = match uuid {
    Some(uuid) => uuid
    None => @uuid.generator(@rand.chacha8())
  }
  let cwd = match cwd {
    Some(cwd) => cwd.to_string()
    None => @os.cwd()
  }
  Daemon::{
    clock: @clock.epoch,
    models: @model.Loader::new(home=@os.home(), cwd~, logger~),
    uuid,
    process: @spawn.Manager::new(cwd~),
    by_cwd: {},
    by_id: {},
    rqs: {},
    exec_path,
    tcp_server,
    port,
    events: @broadcast.Broadcast::new(),
    serve,
  }
}

///|
async fn Daemon::serve(self : Daemon) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(() => self.process.start())
    self.tcp_server.run_forever((conn, _) => {
      let conn = @http.ServerConnection::new(conn)
      let r = conn.read_request()
      println("[INFO] (Daemon) Received request: \{r.meth} \{r.path}")
      let paths = r.path.split("/").collect()
      println("[INFO] (Daemon) Handling request paths: \{paths}")
      try {
        match (r.meth, paths) {
          // GET /
          (Get, ["", ""]) => {
            let index_html = html_read_file(
              @path.join(self.serve, "index.html"),
            )
            conn
            ..send_response(200, "OK", extra_headers={
              "Content-Type": "text/html",
              "Access-Control-Allow-Origin": "*",
              "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
              "Access-Control-Allow-Headers": "Content-Type",
            })
            ..write(index_html)
            ..end_response()
          }
          (Get, ["", "v1", "events"]) => self.get_events(conn)
          (Get, ["", "v1", "models"]) => self.list_models(conn)
          (Post, ["", "v1", "task", "register"]) => self.register_task(conn)
          (Get, ["", "v1", "tasks"]) => self.list_tasks(conn)
          (Post, ["", "v1", "task"]) => self.create_task(group~, conn)
          (Get, ["", "v1", "task", id]) => self.get_task(id, conn)
          (Get, ["", "v1", "task", id, "events"]) =>
            self.get_task_events(id, conn)
          (Get, ["", "v1", "task", id, "moonbit", "modules"]) =>
            self.list_moonbit_modules(id, r, conn)
          (Post, ["", "v1", "moonbit", "publish"]) =>
            publish_moonbit_module(conn)
          (Post, ["", "v1", "task", id, "message"]) =>
            self.create_task_message(id, conn)
          (Get, ["", .. file]) =>
            serve_static_file(conn, serve=self.serve, path=file.join("/"))
          _ =>
            raise json_error(404, "NotFound", {
              "error": {
                "code": -1,
                "message": "Unknown endpoint: \{r.path}",
                "metadata": { "method": r.meth.to_string(), "path": r.path },
              },
            })
        }
      } catch {
        HttpError(code~, reason~, body~) => {
          conn.send_response(code, reason, extra_headers={
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS, POST",
            "Access-Control-Allow-Headers": "Content-Type",
          })
          conn.write(body)
          conn.end_response()
        }
        error => raise error
      }
    })
  })
}
