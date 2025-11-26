///|
struct Daemon {
  clock : &@clock.Clock
  models : @model.Loader
  uuid : @uuid.Generator
  process : @spawn.Manager
  by_cwd : Map[String, Task]
  by_id : Map[@uuid.Uuid, Task]
  rqs : Map[String, @aqueue.Queue[Int]]
  exec_path : String
  httpx : @httpx.Server
  port : Int
  events : @broadcast.Broadcast[Event]
  serve : String
}

///|
pub fn Daemon::port(self : Daemon) -> Int {
  self.port
}

///|
priv enum Event {
  StatusChange(@uuid.Uuid)
}

///|
async fn Daemon::get_events(self : Daemon, w : @httpx.ResponseWriter) -> Unit {
  w.header().set("Content-Type", "text/event-stream")
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.header().set("X-Accel-Buffering", "no")
  w.write_header(200)
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
  let (er, eb) = @http.get_stream("http://localhost:\{task.port}/v1/events")
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
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  guard {
      let bytes = r.body.read_all().binary()
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
    "server",
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
  let rq = @aqueue.Queue::new(kind=Unbounded)
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
      "http://localhost:\{task_port}/v1/message",
      ({ "message": message } : Json),
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
  w.header().set("Content-Type", "application/json")
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.write_header(201, reason="Created")
  let body : Json = { "task": task }
  w.write(body.stringify())
}

///|
async fn Daemon::list_models(self : Daemon, w : @httpx.ResponseWriter) -> Unit {
  let models : Array[Json] = []
  for model in self.models.models() {
    models.push({ "name": model.name })
  }
  let response : Json = { "models": models }
  w.header().set("Content-Type", "application/json")
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.write_header(200)
  w.write(response.stringify())
}

///|
async fn Daemon::register_task(
  self : Daemon,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let request_bytes = r.body.read_all().binary()
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
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.write_header(200)
}

///|
async fn Daemon::list_tasks(self : Daemon, w : @httpx.ResponseWriter) -> Unit {
  let tasks = self.by_cwd.values().collect()
  let response : Json = { "tasks": tasks }
  w.header().set("Content-Type", "application/json")
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.write_header(200)
  w.write(response.stringify())
}

///|
async fn Daemon::get_task(
  self : Daemon,
  id : StringView,
  w : @httpx.ResponseWriter,
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
  w.header().set("Content-Type", "application/json")
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.write_header(200)
  w.write(response.stringify())
}

///|
async fn Daemon::get_task_events(
  self : Daemon,
  id : StringView,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
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
  let (r, c) = @http.get_stream(
    "http://localhost:\{task.port}/v1/events",
    body=r.body.read_all(),
  )
  w.header().set("Content-Type", "text/event-stream")
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.header().set("X-Accel-Buffering", "no")
  w.write_header(r.code, reason=r.reason)
  w.write_reader(c)
  w.flush()
}

///|
async fn Daemon::list_moonbit_modules(
  self : Daemon,
  id : StringView,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
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
  let (r, b) = @http.get(
    "http://localhost:\{server.port}/v1/moonbit/modules",
    body=r.body.read_all(),
  )
  w.header().set("Content-Type", "application/json")
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.write_header(r.code, reason=r.reason)
  w.write(b)
}

///|
async fn Daemon::create_task_message(
  self : Daemon,
  id : StringView,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
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
    "http://localhost:\{task.port}/v1/message",
    r.body.read_all(),
  )
  println(
    "[INFO] (Daemon) Forwarded message to task \{id} @ localhost:\{task.port}",
  )
  w.header().set("Content-Type", "application/json")
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.write_header(response.code, reason=response.reason)
  w.write(response_body)
}

///|
async fn Daemon::cancel_task(
  self : Daemon,
  id : StringView,
  w : @httpx.ResponseWriter,
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
  let (r, b) = @http.post(
    "http://localhost:\{task.port}/v1/cancel",
    Json::object({}),
  )
  println("[INFO] (Daemon) Sent cancel request to task \{id}")
  w.header().set("Content-Type", "application/json")
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  w.write_header(r.code, reason=r.reason)
  w.write(b)
}

///|
pub async fn Daemon::new(
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
  let httpx_server = @httpx.Server::new("[::1]", port, reuse_addr=true)
  let port = httpx_server.port()
  println("[INFO] Starting HTTP server on port \{port}...")
  println("[INFO] Visit http://localhost:\{port}/")
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
    models: @model.Loader::new(home=@os.home(), cwd~),
    uuid,
    process: @spawn.Manager::new(cwd~),
    by_cwd: {},
    by_id: {},
    rqs: {},
    exec_path,
    httpx: httpx_server,
    port,
    events: @broadcast.Broadcast::new(),
    serve,
  }
}

///|
pub async fn Daemon::serve(self : Daemon) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(() => self.process.start())
    self.httpx.serve((r, w) => {
      println("[INFO] (Daemon) Received request: \{r.method_} \{r.path}")
      let paths = r.path.split("/").collect()
      println("[INFO] (Daemon) Handling request paths: \{paths}")
      try {
        match (r.method_, paths) {
          (Options, _) => {
            w.header().set("Access-Control-Allow-Origin", "*")
            w.header().set("Access-Control-Allow-Methods", "*")
            w.header().set("Access-Control-Allow-Headers", "*")
            w.write_header(204)
          }
          // GET /
          (Get, ["", ""]) => {
            let index_html = html_read_file(
              @path.join(self.serve, "index.html"),
            )
            w.header().set("Content-Type", "text/html")
            w.header().set("Access-Control-Allow-Origin", "*")
            w.header().set("Access-Control-Allow-Methods", "*")
            w.header().set("Access-Control-Allow-Headers", "*")
            w.write_header(200)
            w.write(index_html)
          }
          (Get, ["", "v1", "events"]) => self.get_events(w)
          (Get, ["", "v1", "models"]) => self.list_models(w)
          (Post, ["", "v1", "task", "register"]) => self.register_task(r, w)
          (Get, ["", "v1", "tasks"]) => self.list_tasks(w)
          (Post, ["", "v1", "task"]) => self.create_task(group~, r, w)
          (Get, ["", "v1", "task", id]) => self.get_task(id, w)
          (Get, ["", "v1", "task", id, "events"]) =>
            self.get_task_events(id, r, w)
          (Get, ["", "v1", "task", id, "moonbit", "modules"]) =>
            self.list_moonbit_modules(id, r, w)
          (Post, ["", "v1", "moonbit", "publish"]) =>
            publish_moonbit_module(r, w)
          (Post, ["", "v1", "task", id, "message"]) =>
            self.create_task_message(id, r, w)
          (Post, ["", "v1", "task", id, "cancel"]) => self.cancel_task(id, w)
          (Get, ["", .. file]) =>
            serve_static_file(w, serve=self.serve, path=file.join("/"))
          _ =>
            raise json_error(404, "NotFound", {
              "error": {
                "code": -1,
                "message": "Unknown endpoint: \{r.path}",
                "metadata": { "method": r.method_.to_string(), "path": r.path },
              },
            })
        }
      } catch {
        HttpError(code~, reason~, body~) => {
          w.header().set("Content-Type", "application/json")
          w.header().set("Access-Control-Allow-Origin", "*")
          w.header().set("Access-Control-Allow-Methods", "*")
          w.header().set("Access-Control-Allow-Headers", "*")
          w.write_header(code, reason~)
          w.write(body)
        }
        error => raise error
      }
    })
  })
}
