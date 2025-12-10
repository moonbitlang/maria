///|
struct Task {
  name : String?
  id : @uuid.Uuid
  cwd : String
  port : Int
  mut status : @server.Status
  queued_messages : Array[QueuedMessage]
  created : Int64
  web_search : Bool
}

///|
pub fn Task::is_idle(self : Task) -> Bool {
  self.status is @server.Idle
}

///|
fn Task::new(
  name? : String,
  id~ : @uuid.Uuid,
  cwd~ : String,
  port~ : Int,
  created~ : Int64,
  web_search~ : Bool,
) -> Task {
  Task::{
    name,
    id,
    cwd,
    port,
    status: @server.Idle,
    queued_messages: [],
    created,
    web_search,
  }
}

///|
async fn Task::sync(task : Task) -> Unit {
  task.sync_status()
  task.sync_queued_messages()
}

///|
async fn Task::sync_status(task : Task) -> Unit {
  let (r, b) = @http.get("http://localhost:\{task.port}/v1/status") catch {
    error => {
      println(
        "[WARN] (Daemon) Failed to sync status from task \{task.id}: \{error}",
      )
      raise error
    }
  }
  guard r.code is (200..=299) else {
    println(
      "[WARN] (Daemon) Failed to sync status from task \{task.id}: \{r.code} \{r.reason}",
    )
    return
  }
  let b = b.json() catch {
    error => {
      println(
        "[WARN] (Daemon) Failed to parse status JSON from task \{task.id}: \{error}",
      )
      raise error
    }
  }
  guard b is { "status": String(status_str), .. } else {
    println("[WARN] (Daemon) Invalid status format from task \{task.id}")
    return
  }
  match status_str.to_lower() {
    "idle" => task.status = @server.Idle
    "generating" => task.status = @server.Busy
    _ =>
      println(
        "[WARN] (Daemon) Unknown status '\{status_str}' from task \{task.id}",
      )
  }
}

///|
async fn Task::sync_queued_messages(task : Task) -> Unit {
  task.queued_messages.clear()
  let (r, b) = @http.get("http://localhost:\{task.port}/v1/queued-messages") catch {
    error =>
      raise json_error(500, "Internal Server Error", {
        "error": {
          "code": -1,
          "message": "Failed to get queued messages from task: \{error}",
          "metadata": error.to_json(),
        },
      })
  }
  guard r.code is (200..=299) else {
    raise json_error(500, "Internal Server Error", {
      "error": {
        "code": r.code,
        "message": "Failed to get queued messages from task: \{r.code} \{r.reason}",
        "metadata": { "code": r.code, "reason": r.reason, "body": b.json() },
      },
    })
  }
  let b = b.json() catch {
    error =>
      raise json_error(500, "Internal Server Error", {
        "error": {
          "code": -1,
          "message": "Failed to parse queued messages JSON from task: \{error}",
          "metadata": error.to_json(),
        },
      })
  }
  guard b is Array(queued_messages) else {
    raise json_error(500, "Internal Server Error", {
      "error": {
        "code": -1,
        "message": "Invalid queued messages format from task",
        "metadata": { "body": b },
      },
    })
  }
  for m in queued_messages {
    guard m is { "id": String(id), "message": message, .. } else { continue }
    task.queued_messages.push({ id, message })
  }
}

///|
priv struct QueuedMessage {
  id : String
  message : Json
} derive(ToJson, @json.FromJson)

///|
pub impl @json.FromJson for Task with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Task {
  guard json is Object(map) else {
    raise @json.JsonDecodeError((json_path, "Task::from_json: expected object"))
  }
  let name = match map.get("name") {
    Some([String(name)]) | Some(String(name)) => Some(name)
    None | Some(Null) => None
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path.add_key("name"), "Task::from_json: expected string or null"),
      )
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
    Some(String(cwd)) => cwd
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("cwd"), "Task::from_json: expected string"),
      )
  }
  let port = match map.get("port") {
    Some(Number(port, ..)) => port.to_int()
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("port"), "Task::from_json: expected number"),
      )
  }
  let status = match map.get("status") {
    Some(String(status_str)) =>
      match status_str.to_lower() {
        "idle" => @server.Idle
        "generating" => @server.Busy
        _ =>
          raise @json.JsonDecodeError(
            (
              json_path.add_key("status"),
              "Task::from_json: unknown status '\{status_str}'",
            ),
          )
      }
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("status"), "Task::from_json: expected string"),
      )
  }
  let web_search = match map.get("web_search") {
    Some(True) => true
    Some(False) => false
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("web_search"), "Task::from_json: expected bool"),
      )
  }
  let created = match map.get("created") {
    Some(Number(created_num, repr=None)) => {
      guard created_num >= 0.0 else {
        raise @json.JsonDecodeError(
          (
            json_path.add_key("created"),
            "Task::from_json: created timestamp cannot be negative",
          ),
        )
      }
      created_num.to_int64()
    }
    Some(Number(_, repr=Some(created_str)) | String(created_str)) =>
      @strconv.parse_int64(created_str) catch {
        error =>
          raise @json.JsonDecodeError(
            (
              json_path.add_key("created"),
              "Task::from_json: invalid Int64 string: \{error}",
            ),
          )
      }
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("created"), "Task::from_json: expected number"),
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
  Task::{ name, id, cwd, port, status, created, web_search, queued_messages }
}

///|
pub impl ToJson for Task with to_json(self : Task) -> Json {
  {
    "name": self.name,
    "id": self.id.to_string(),
    "cwd": self.cwd,
    "port": self.port,
    "status": self.status,
    "created": Json::number(
      self.created.to_double(),
      repr=self.created.to_string(),
    ),
    "web_search": self.web_search,
    "queued_messages": self.queued_messages,
  }
}

///|
test "Task::ToJson" {
  let task = Task::{
    name: Some("example"),
    id: @uuid.parse("123e4567-e89b-12d3-a456-426614174000"),
    cwd: "/tmp/example",
    port: 8080,
    status: @server.Idle,
    queued_messages: [
      QueuedMessage::{ id: "msg1", message: { "text": "Hello" } },
    ],
    created: 0,
    web_search: true,
  }
  @json.inspect(task, content={
    "name": ["example"],
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "cwd": "/tmp/example",
    "port": 8080,
    "status": "idle",
    "created": 0,
    "web_search": true,
    "queued_messages": [{ "id": "msg1", "message": { "text": "Hello" } }],
  })
}
