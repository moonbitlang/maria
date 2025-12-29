///|
pub impl @json.FromJson for Task with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Task {
  let object = @jsonx.as_object(json, path=json_path)
  let name = match object.get("name") {
    Some([String(name)]) | Some(String(name)) => Some(name)
    None | Some(Null) => None
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path.add_key("name"), "Task::from_json: expected string or null"),
      )
  }
  let id_str : String = object.required("id", path=json_path)
  let id = @uuid.parse(id_str) catch {
    error =>
      raise @json.JsonDecodeError(
        (
          json_path.add_key("id"),
          "Task::from_json: invalid UUID string: \{error}",
        ),
      )
  }
  let cwd : String = object.required("cwd", path=json_path)
  let port : Int = object.required("port", path=json_path)
  let status_str : String = object.required("status", path=json_path)
  let status = match status_str.to_lower() {
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
  let web_search : Bool = object.required("web_search", path=json_path)
  let created : @clock.Timestamp = object.required("created", path=json_path)
  let queued_messages : Array[QueuedMessage] = match
    object.get("queued_messages") {
    None => []
    Some(queued_messages_json) =>
      @json.from_json(
        queued_messages_json,
        path=json_path.add_key("queued_messages"),
      )
  }
  Task::{ name, id, cwd, port, status, created, web_search, queued_messages }
}

///|
pub impl ToJson for Task with to_json(self : Task) -> Json {
  let object : Map[String, Json] = {}
  if self.name is Some(name) {
    object["name"] = name.to_json()
  } else {
    object["name"] = Json::null()
  }
  object.merge_in_place({
    "id": self.id.to_string(),
    "cwd": self.cwd,
    "port": self.port,
    "status": self.status,
    "created": self.created,
    "web_search": self.web_search,
    "queued_messages": self.queued_messages,
  })
  Json::object(object)
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
    created: @clock.Timestamp::from_ms(0),
    web_search: true,
  }
  assert_eq(task.to_json(), {
    "name": "example",
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "cwd": "/tmp/example",
    "port": 8080,
    "status": "idle",
    "created": 0,
    "web_search": true,
    "queued_messages": [{ "id": "msg1", "message": { "text": "Hello" } }],
  })
}
