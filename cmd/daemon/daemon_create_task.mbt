///|
/// Request to create a new Maria task.
priv struct CreateTaskRequest {
  /// Human-readable name for the task. If not provided, this field
  /// will be `None`.
  name : String?
  /// Identifier of the AI model to use for the task. If not
  /// provided, a default model will be selected.
  model : String?
  /// Initial message to send to the task after creation.
  /// Must conform to OpenAI's chat completion message format.
  message : @openai.ChatCompletionMessageParam?
  /// Working directory path for the task. If not provided, a
  /// temporary directory will be created automatically.
  cwd : String?
  /// Flag to enable web search capabilities for the
  /// task. Defaults to false if not specified.
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
/// Creates a new Maria task from a JSON request, spawning a server process and
/// optionally sending an initial message.
///
/// This method handles the complete lifecycle of task creation: parses the
/// request body, validates the model and working directory, spawns a new server
/// process with a unique ID, waits for the process to register itself, and
/// optionally sends an initial message to the newly created task.
///
/// Parameters:
///
/// * `self` : The daemon instance that will manage the new task.
/// * `group` : The async task group used to spawn background processes for task
///   management and status monitoring.
/// * `r` : The HTTP request reader containing the JSON request body with task
///   configuration.
/// * `w` : The HTTP response writer used to send the task creation response.
///
/// Throws an `HttpError` under various conditions:
///
/// * 400 Bad Request: Invalid UTF-8 encoding, malformed JSON, or invalid
///   request structure
/// * 404 Not Found: Specified model doesn't exist or working directory path
///   doesn't exist
/// * 409 Conflict: A task already exists for the specified working directory
/// * 500 Internal Server Error: Filesystem operations fail, process spawning
///   fails, task registration timeout (5 minutes), or communication with the
///   spawned task fails
///
/// The method responds with HTTP 201 Created and a JSON body containing the
/// created task information and optionally the response from sending the
/// initial message.
async fn Daemon::create_task(
  self : Daemon,
  group~ : @async.TaskGroup[Unit],
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let r : @httpx.JsonRequestReader = @httpx.JsonRequestReader::new(r)
  let request : CreateTaskRequest = r.read()
  // Load model
  guard self.models.get_model(name?=request.model) is Some(model) else {
    raise json_error(404, "Not Found", {
      "error": { "code": -1, "message": "Model not found: \{request.model}" },
    })
  }
  // Create temporary working directory if not specified
  let cwd = check_working_directory(request.cwd)
  // Check if a running task already exists for the specified cwd, if not
  // spawn a new task.
  let task_list = self.by_cwd.get_or_init(cwd, () => TaskLock::new())
  // Check if a running task already exists for the specified cwd. If so, raise
  // a 409 Conflict error.
  guard task_list.running is None else {
    raise json_error(409, "Conflict", {
      "error": {
        "code": -1,
        "message": "A running task already exists for the specified 'cwd': \{cwd}",
        "metadata": { "cwd": cwd },
      },
    })
  }
  let task = {
    task_list.spawn_mutex.acquire()
    // Deferring the release of the mutex to ensure it is released even if an
    // error occurs during task spawning.
    defer task_list.spawn_mutex.release()
    let task = self.spawn_task(
      group~,
      name?=request.name,
      model~,
      web_search=request.web_search is Some(true),
      cwd~,
    )
    // Register the task in the daemon's task lists.
    task_list.running = Some(task)
    task
  }
  let message = if request.message is Some(message) {
    logger.info("Write initial messages to task '\{task.id}'...")
    Some(
      task.create_message(
        @server.CreateMessageRequest::new(
          message=@ai.Message::from_openai(message),
          web_search=request.web_search is Some(true),
        ),
      ),
    )
  } else {
    None
  }
  w.header().set("Content-Type", "application/json")
  w.write_header(201, reason="Created")
  let response = CreateTaskResponse::{ task, message }
  w.write(response.to_json().stringify(indent=2))
}

///|
/// Response structure for task creation operations containing the newly created
/// task and optional message response.
priv struct CreateTaskResponse {
  /// The running task that was successfully created and registered
  /// with the daemon.
  task : Running
  /// Optional response from sending an initial message to the newly
  /// created task. Present only when an initial message was provided in the
  /// creation request.
  message : @server.CreateMessageResponse?
}

///|
impl ToJson for CreateTaskResponse with to_json(self : CreateTaskResponse) -> Json {
  let object : Map[String, Json] = { "task": self.task.to_json() }
  if self.message is Some(message) {
    object["message"] = message.to_json()
  }
  Json::object(object)
}

///|
/// Validates or creates a working directory for a Maria task.
///
/// If `cwd` is `None`, creates a temporary directory in the system's temporary
/// directory with a unique name following the pattern
/// "maria-server-task-XXXXXX". If `cwd` is provided, validates that the
/// specified directory exists.
///
/// Parameters:
///
/// * `cwd` : An optional path to the working directory. If `None`, a temporary
///   directory will be created.
///
/// Returns the path to the validated or newly created working directory.
///
/// Throws an `HttpError` under the following conditions:
///
/// * 500 Internal Server Error: If creating a temporary directory fails or if
///   checking the existence of the specified directory fails
/// * 404 Not Found: If the specified `cwd` path does not exist
async fn check_working_directory(cwd : String?) -> String {
  guard cwd is Some(cwd) else {
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
}
