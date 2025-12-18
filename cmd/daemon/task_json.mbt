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
    "created": Json::number(
      self.created.to_double(),
      repr=self.created.to_string(),
    ),
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
    created: 0,
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
