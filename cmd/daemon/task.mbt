///|
priv struct Task {
  name : String?
  id : @uuid.Uuid
  cwd : String
  port : Int
  mut status : @server.Status
  created : Int64
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
async fn Task::queued_messages(task : Task) -> Array[QueuedMessage] {
  let ms = []
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
    ms.push({ id, message })
  }
  ms
}

///|
priv struct QueuedMessage {
  id : String
  message : Json
} derive(ToJson)

///|
impl ToJson for Task with to_json(self : Task) -> Json {
  Json::object(self.to_json_object())
}

///|
fn Task::to_json_object(self : Task) -> Map[String, Json] {
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
    created: 0,
  }
  @json.inspect(task, content={
    "name": ["example"],
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "cwd": "/tmp/example",
    "port": 8080,
    "status": "idle",
    "created": 0,
  })
}
