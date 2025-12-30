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
  let object = @jsonx.as_object(json, path=json_path)
  let name : String? = object.optional("name", path=json_path)
  let model : String? = object.optional("model", path=json_path)
  let message : @openai.ChatCompletionMessageParam? = object.optional(
    "message",
    path=json_path,
  )
  let cwd : String? = object.optional("cwd", path=json_path)
  let web_search : Bool? = object.optional("web_search", path=json_path)
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
/// Creates and registers a new Maria task process, optionally sending an
/// initial message to the task.
///
/// Endpoint: POST /v1/task
///
/// Request:
/// - Body: JSON `CreateTaskRequest` with optional fields:
///   - `name?`: human-friendly task name
///   - `model?`: model name to run the task server
///   - `message?`: initial `ChatCompletionMessageParam` sent to the task
///   - `cwd?`: working directory; if omitted, a temp dir is created
///   - `web_search?`: enable web search capability for the task
///
/// Response:
/// - 201 Created: JSON `{ "task": Task, "message"?: Json }` where `message`
///   is present only when an initial message was sent successfully.
///
/// Errors:
/// - 400 Bad Request: Invalid UTF-8/JSON in body or decode failures.
/// - 404 Not Found: Unknown `model` or non-existent provided `cwd`.
/// - 409 Conflict: A task is already registered for the same `cwd`.
/// - 500 Internal Server Error: Process spawn, filesystem, or HTTP failures.
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
  let created = self.clock.now()
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
