///|
/// Long-lived supervisor that exposes Maria's REST API and fans out requests
/// to per-workspace tasks. `Daemon` owns the HTTP server, process manager, and
/// bookkeeping maps for active tasks.
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
/// Returns the actual TCP port the daemon bound to after the HTTP server is
/// created. This is useful when callers asked for `--port 0` (ephemeral port)
/// and need to propagate the assigned value.
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
  w.header().set("X-Accel-Buffering", "no")
  w.write_header(200)
  let tasks : Array[Task] = []
  for task in self.by_cwd.values().collect() {
    task.sync_status() catch {
      error =>
        println(
          "[WARN] (Daemon) Failed to sync status from task \{task.id}: \{error}",
        )
    }
    tasks.push(task)
  }
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
  let eb = @httpx.EventStreamReader::new(eb)
  while eb.read_event() is Some(event) {
    guard event.event is Some("maria") else { continue }
    let json = @json.parse(event.data)
    let event : @event.Event = @json.from_json(json)
    if event.is_stopping() || event.is_cancellation() {
      println("[INFO] (Daemon) Task \{task.id} is now idle.")
      task.status = Idle
      self.events.put(StatusChange(task.id))
    } else if event.is_starting() {
      println("[INFO] (Daemon) Task \{task.id} is now busy.")
      task.status = Busy
      self.events.put(StatusChange(task.id))
    }
  }
}

///|
priv struct CreateTaskRequest {
  name : String?
  model : String?
  message : @openai.ChatCompletionMessageParam?
  cwd : String?
  web_search : Bool?
}

///|
impl @json.FromJson for CreateTaskRequest with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> CreateTaskRequest raise @json.JsonDecodeError {
  guard json is Object(json) else {
    raise @json.JsonDecodeError(
      (json_path, "Expected JSON object for CreateTaskRequest"),
    )
  }
  let name : String? = match json.get("name") {
    Some(Null) => None
    Some(name_json) =>
      Some(@json.from_json(name_json, path=json_path.add_key("name")))
    None => None
  }
  let model : String? = match json.get("model") {
    Some(Null) => None
    Some(model_json) =>
      Some(@json.from_json(model_json, path=json_path.add_key("model")))
    None => None
  }
  let message : @openai.ChatCompletionMessageParam? = match
    json.get("message") {
    Some(Null) => None
    Some(message_json) =>
      Some(@json.from_json(message_json, path=json_path.add_key("message")))
    None => None
  }
  let cwd : String? = match json.get("cwd") {
    Some(Null) => None
    Some(cwd_json) =>
      Some(@json.from_json(cwd_json, path=json_path.add_key("cwd")))
    None => None
  }
  let web_search : Bool? = match json.get("web_search") {
    Some(Null) => None
    Some(web_search_json) =>
      Some(
        @json.from_json(web_search_json, path=json_path.add_key("web_search")),
      )
    None => None
  }
  CreateTaskRequest::{ name, model, message, cwd, web_search }
}

///|
test "CreateTaskRequest::from_json" {
  let json : Json = {
    "name": "Test Task",
    "model": "gpt-4",
    "message": { "role": "user", "content": "Hello, world!" },
    "cwd": "/tmp/task",
  }
  let request : CreateTaskRequest = @json.from_json(json)
  @json.inspect(request.name, content=["Test Task"])
  @json.inspect(request.model, content=["gpt-4"])
  @json.inspect(request.message, content=[
    { "role": "user", "content": "Hello, world!" },
  ])
  @json.inspect(request.cwd, content=["/tmp/task"])
  let json : Json = {}
  let request : CreateTaskRequest = @json.from_json(json)
  @json.inspect(request.name, content=null)
  @json.inspect(request.model, content=null)
  @json.inspect(request.message, content=null)
  @json.inspect(request.cwd, content=null)
  let json : Json = {
    "name": null,
    "model": null,
    "message": null,
    "cwd": null,
  }
  let request : CreateTaskRequest = @json.from_json(json)
  @json.inspect(request.name, content=null)
  @json.inspect(request.model, content=null)
  @json.inspect(request.message, content=null)
  @json.inspect(request.cwd, content=null)
  @json.inspect(request.web_search, content=null)
  let json : Json = { "web_search": true }
  let request : CreateTaskRequest = @json.from_json(json)
  @json.inspect(request.web_search, content=[true])
}

///|
async fn Daemon::create_task(
  self : Daemon,
  group~ : @async.TaskGroup[Unit],
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let request : CreateTaskRequest = {
    let bytes = r.body.read_all().binary()
    let text = @encoding/utf8.decode(bytes) catch {
      @encoding/utf8.Malformed(bytes) =>
        raise json_error(400, "Bad Request", {
          "error": {
            "code": -1,
            "message": "Invalid UTF-8 in request body: \{bytes}",
            "data": { "body": bytes },
          },
        })
    }
    let json = @json.parse(text) catch {
      error =>
        raise json_error(400, "Bad Request", {
          "error": {
            "code": -1,
            "message": "Invalid JSON in request body: \{error}",
            "data": { "body": text },
          },
        })
    }
    @json.from_json(json) catch {
      error =>
        raise json_error(400, "Bad Request", {
          "error": {
            "code": -1,
            "message": "Failed to decode CreateTaskRequest: \{error}",
            "data": { "body": json, "error": error.to_json() },
          },
        })
    }
  }
  guard self.models.get_model(name?=request.model) is Some(model) else {
    raise json_error(404, "Not Found", {
      "error": { "code": -1, "message": "Model not found: \{request.model}" },
    })
  }
  let cwd = if request.cwd is Some(cwd) {
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
    @fsx.mkdtemp(@pathx.join(@os.tmpdir(), "maria-server-task-XXXXXX")) catch {
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
  if request.web_search is Some(true) {
    args.push("--web-search")
  }
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
  let task = Task::new(
    name?=request.name,
    id~,
    cwd~,
    port=task_port,
    created~,
    web_search=request.web_search is Some(true),
  )
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
  let message = if request.message is Some(message) {
    let msg_req : Map[String, Json] = { "message": message.to_json() }
    if request.web_search is Some(web_search) {
      msg_req["web_search"] = web_search.to_json()
    }
    println("[INFO] (Daemon) Write initial messages to task '\{id}'...")
    let (r, b) = @httpx.post_json(
      "http://localhost:\{task_port}/v1/message",
      Json::object(msg_req),
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
    Some(b.json()) catch {
      error =>
        raise json_error(500, "Internal Server Error", {
          "error": {
            "code": -1,
            "message": "Failed to parse response JSON from task: \{error}",
            "metadata": { "body": b.binary() },
          },
        })
    }
  } else {
    None
  }
  w.header().set("Content-Type", "application/json")
  w.write_header(201, reason="Created")
  let body : Map[String, Json] = { "task": task }
  if message is Some(message) {
    body["message"] = message
  }
  w.write(Json::object(body).stringify())
}

///|
async fn Daemon::list_models(self : Daemon, w : @httpx.ResponseWriter) -> Unit {
  let models : Array[Json] = []
  for model in self.models.models() {
    models.push({ "name": model.name })
  }
  let response : Json = { "models": models }
  w.header().set("Content-Type", "application/json")
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
  let register : @server.RegisterRequest = @json.from_json(request_json) catch {
    error =>
      raise json_error(
        400,
        "Bad Request",
        "Failed to decode RegisterRequest: \{error}",
      )
  }
  println("[INFO] Registered task '\{register.id}' on port \{register.port}")
  self.rqs[register.id].put(register.port)
  w.write_header(200)
  let res : @server.RegisterResponse = @server.RegisterResponse::{  }
  w.write(res.to_json())
}

///|
async fn Daemon::list_tasks(self : Daemon, w : @httpx.ResponseWriter) -> Unit {
  let tasks = self.by_cwd.values().collect()
  let response : Json = { "tasks": tasks }
  w.header().set("Content-Type", "application/json")
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
  task.sync()
  let response : Json = { "task": task }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.stringify())
}

///|
async fn lock_daemon_file(home~ : StringView) -> @fs.File? {
  let path = home |> @pathx.join(".moonagent") |> @pathx.join("daemon.json")
  let dir = @pathx.dirname(path)
  @fsx.make_directory(dir, recursive=true, exists_ok=true)
  let file = @fs.open(path, mode=WriteOnly, create=0o644)
  @fsx.lock_file(file) catch {
    @errno.Errno(errno) if errno == @errno.eacces || errno == @errno.eagain =>
      return None
    error => raise error
  }
  // Note that file is intentionally not closed here to keep the lock.
  return Some(file)
}

///|
/// Constructs a daemon instance, validates the executable path, optionally
/// acquires the `~/.moonagent/daemon.json` lock, and binds the HTTP server.
/// Returns `None` when another daemon already holds the lock.
pub async fn Daemon::new(
  uuid? : @uuid.Generator,
  exec_path~ : String,
  port~ : Int,
  serve~ : String,
  cwd? : StringView,
  home? : StringView,
  lock? : Bool = true,
) -> Daemon? {
  let home = match home {
    None => @os.home()
    Some(home) => home.to_string()
  }
  // Validate exec_path points to an existing file.
  if !@fsx.exists(exec_path) {
    fail("Exec path does not exist: \{exec_path}")
  }
  let exec_path = @fsx.resolve(exec_path) catch {
    error => fail("Failed to resolve exec path '\{exec_path}': \{error}")
  }
  let info_file = if lock {
    // Grab daemon lock file
    guard lock_daemon_file(home~) is Some(info_file) else {
      println(
        "[INFO] Another Maria daemon is already running for home '\{home}'. Exiting.",
      )
      return None
    }
    Some(info_file)
  } else {
    None
  }
  // Listen on port
  let httpx_server = @httpx.Server::new("[::1]", port, reuse_addr=true)
  let port = httpx_server.port()
  if info_file is Some(info_file) {
    @fsx.truncate(info_file, 0)
    info_file.write(
      DaemonInfo::{ port, pid: @spawn.getpid() }.to_json().stringify(),
    )
  }
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
  Some(Daemon::{
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
  })
}

///|
/// Runs the daemon event loop: starts the task manager, serves HTTP requests
/// (behind the shared CORS middleware), and blocks until cancelled.
pub async fn Daemon::serve(self : Daemon) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(() => self.process.start())
    self.httpx.serve(
      @httpx.cors((r, w) => {
        let paths = r.path.split("/").collect()
        println("[INFO] (Daemon) Received request: \{r.method_} \{r.path}")
        println("[INFO] (Daemon) Handling request paths: \{paths}")
        try {
          match (r.method_, paths) {
            (Options, _) => w.write_header(204)
            // GET /
            (Get, ["", ""]) => {
              let index_html = html_read_file(
                @pathx.join(self.serve, "index.html"),
              )
              w.header().set("Content-Type", "text/html")
              w.write_header(200)
              w.write(index_html)
            }
            (Get, ["", "v1", "events"]) => self.get_events(w)
            (Get, ["", "v1", "models"]) => self.list_models(w)
            (Post, ["", "v1", "task", "register"]) => self.register_task(r, w)
            (Get, ["", "v1", "tasks"]) => self.list_tasks(w)
            (Post, ["", "v1", "task"]) => self.create_task(group~, r, w)
            (Get, ["", "v1", "task", id]) => self.get_task(id, w)
            (method_, ["", "v1", "task", id, .. paths]) =>
              self.forward_to_task(method_~, id~, paths~, r, w)
            (Post, ["", "v1", "shutdown"]) => {
              w.header().set("Content-Type", "application/json")
              w.write_header(200)
              let response : Json = {}
              w.write(response.stringify())
              w.flush()
              // We need to close the writer before shutting down to ensure the
              w.close()
              group.return_immediately(())
            }
            (Post, ["", "v1", "moonbit", "publish"]) =>
              publish_moonbit_module(r, w)
            (Get, ["", .. file]) =>
              serve_static_file(w, serve=self.serve, path=file.join("/"))
            _ =>
              raise json_error(404, "NotFound", {
                "error": {
                  "code": -1,
                  "message": "Unknown endpoint: \{r.path}",
                  "metadata": {
                    "method": r.method_.to_string(),
                    "path": r.path,
                  },
                },
              })
          }
        } catch {
          HttpError(code~, reason~, body~) => {
            w.header().set("Content-Type", "application/json")
            w.write_header(code, reason~)
            w.write(body)
          }
          error => raise error
        }
      }),
    )
  })
}

///|
async fn Daemon::forward_to_task(
  self : Daemon,
  method_~ : @httpx.Method,
  id~ : StringView,
  paths~ : ArrayView[StringView],
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
  let path = paths.join("/")
  let c = @http.Client::new("http://localhost:\{task.port}")
  c.request(method_.to_http(), "/v1/\{path}")
  c.write_reader(r.body)
  let r = c.end_request()
  if r.headers.get("content-type") is Some(content_type) {
    w.header().set("Content-Type", content_type)
    if content_type is "text/event-stream" {
      w.header().set("X-Accel-Buffering", "no")
    }
  }
  w.write_header(r.code, reason=r.reason)
  w.write_reader(c)
  w.flush()
}
