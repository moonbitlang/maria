///|
/// Active task instance with runtime state and communication capabilities.
priv struct Running {
  /// Optional human-readable name for the task.
  name : String?
  /// Unique identifier for the task.
  id : @uuid.Uuid
  /// Working directory where the task is executing.
  cwd : String
  /// HTTP port number where the task's server is listening.
  port : Int
  /// Current execution status of the task (idle or busy).
  mut status : @server.Status
  /// Messages waiting to be processed by the task.
  queued_messages : Array[QueuedMessage]
  /// Unix timestamp when the task was created.
  created : @clock.Timestamp
  /// Unix timestamp when the task was last updated.
  updated : @clock.Timestamp
  /// Whether the task has web search capabilities enabled.
  web_search : Bool
  /// The model being used by the task.
  model : String
  broadcast : @broadcast.Broadcast[@server.ServerStreamEvent]
}

///|
/// Checks whether the running task is currently idle.
///
/// Parameters:
///
/// * `self` : The running task to check the status of.
///
/// Returns `true` if the task's status is idle, `false` otherwise.
fn Running::is_idle(self : Running) -> Bool {
  self.status is @server.Idle
}

///|
/// Creates a new running task instance with the specified configuration and
/// initializes it in an idle state.
///
/// Parameters:
///
/// * `name` : Optional human-readable name for the task.
/// * `id` : Unique identifier for the task.
/// * `cwd` : Working directory where the task will execute.
/// * `port` : HTTP port number where the task's server will listen.
/// * `created` : Unix timestamp when the task was created.
/// * `web_search` : Whether the task has web search capabilities enabled.
///
/// Returns a new `Running` task instance with status set to idle and an empty
/// message queue.
fn Running::new(
  name? : String,
  id~ : @uuid.Uuid,
  cwd~ : String,
  port~ : Int,
  created~ : @clock.Timestamp,
  updated? : @clock.Timestamp = created,
  web_search~ : Bool,
  model~ : String,
  broadcast~ : @broadcast.Broadcast[@server.ServerStreamEvent],
) -> Running {
  Running::{
    name,
    id,
    cwd,
    port,
    status: @server.Idle,
    queued_messages: [],
    created,
    updated,
    web_search,
    model,
    broadcast,
  }
}

///|
impl @json.FromJson for Running with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Running {
  guard json is Object(map) else {
    raise @json.JsonDecodeError((json_path, "Task::from_json: expected object"))
  }
  let name = match map.get("name") {
    None | Some(Null) => None
    Some(name) => Some(@json.from_json(name))
  }
  let id = match map.get("id") {
    Some(String(id_str)) =>
      @uuid.parse(id_str) catch {
        error =>
          raise @json.JsonDecodeError(
            (
              json_path.add_key("id"),
              "Task::from_json: invalid UUID string: \{error}",
            ),
          )
      }
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("id"), "Task::from_json: expected string"),
      )
  }
  let cwd = match map.get("cwd") {
    Some(cwd) => @json.from_json(cwd, path=json_path.add_key("cwd"))
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("cwd"), "Task::from_json: expected string"),
      )
  }
  let port = match map.get("port") {
    Some(port) => @json.from_json(port, path=json_path.add_key("port"))
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("port"), "Task::from_json: expected number"),
      )
  }
  let status : @server.Status = match map.get("status") {
    Some(status) => @json.from_json(status, path=json_path.add_key("status"))
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("status"), "Task::from_json: expected string"),
      )
  }
  let web_search = match map.get("web_search") {
    Some(web_search) =>
      @json.from_json(web_search, path=json_path.add_key("web_search"))
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("web_search"), "Task::from_json: expected bool"),
      )
  }
  let created = match map.get("created") {
    Some(created) => @json.from_json(created, path=json_path.add_key("created"))
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("created"), "Task::from_json: expected number"),
      )
  }
  let updated = match map.get("updated") {
    Some(updated) => @json.from_json(updated, path=json_path.add_key("updated"))
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("updated"), "Task::from_json: expected number"),
      )
  }
  let queued_messages = match map.get("queued_messages") {
    Some(Array(qms)) => {
      let ms = Array::new()
      for i, qm_json in qms {
        let qm : QueuedMessage = @json.from_json(
          qm_json,
          path=json_path.add_key("queued_messages").add_index(i),
        )
        ms.push(qm)
      }
      ms
    }
    None => []
    _ =>
      raise @json.JsonDecodeError(
        (
          json_path.add_key("queued_messages"),
          "Task::from_json: expected array",
        ),
      )
  }
  let model = match map.get("model") {
    Some(model) => @json.from_json(model, path=json_path.add_key("model"))
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("model"), "Task::from_json: expected model string"),
      )
  }
  Running::{
    name,
    id,
    cwd,
    port,
    status,
    created,
    updated,
    web_search,
    model,
    queued_messages,
    broadcast: @broadcast.Broadcast::new(),
  }
}

///|
impl ToJson for Running with to_json(self : Running) -> Json {
  let object : Map[String, Json] = {
    "id": self.id.to_string(),
    "cwd": self.cwd,
    "port": self.port,
    "status": self.status,
    "created": self.created,
    "updated": self.updated,
    "web_search": self.web_search,
    "queued_messages": self.queued_messages,
    "model": self.model,
  }
  if self.name is Some(name) {
    object["name"] = name.to_json()
  }
  Json::object(object)
}

///|
async fn Running::create_message(
  self : Running,
  request : @server.CreateMessageRequest,
) -> @server.CreateMessageResponse {
  let (r, b) = @httpx.post_json(
    "http://localhost:\{self.port}/v1/message",
    request.to_json(),
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
  let msg_ret : @server.CreateMessageResponse = @json.from_json(b.json()) catch {
    error =>
      raise json_error(500, "Internal Server Error", {
        "error": {
          "code": -1,
          "message": "Failed to parse response JSON from task: \{error}",
          "metadata": { "body": b.binary() },
        },
      })
  }
  msg_ret
}
