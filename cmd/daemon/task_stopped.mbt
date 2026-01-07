///|
/// Task data representing a stopped process or service.
struct Stopped {
  /// Optional name of the stopped task.
  name : String?
  /// Unique identifier of the stopped task.
  id : @uuid.Uuid
  /// Current working directory where the task was executed. It is possible that
  /// the cwd no longer exists.
  cwd : String
  /// Unix timestamp when the task was created.
  created : @clock.Timestamp
  /// Unix timestamp when the task was last updated.
  updated : @clock.Timestamp
  /// Whether web search functionality is enabled for this task.
  web_search : Bool
  /// Broadcast channel for task events on disk.
  broadcast : @broadcast.Broadcast[@server.ServerStreamEvent]
}

///|
pub impl ToJson for Stopped with to_json(self : Stopped) -> Json {
  let object : Map[String, Json] = {}
  if self.name is Some(name) {
    object["name"] = name.to_json()
  }
  object.merge_in_place({
    "id": self.id,
    "cwd": self.cwd,
    "status": "stopped",
    "created": self.created.to_json(),
    "updated": self.updated.to_json(),
    "web_search": self.web_search,
  })
  Json::object(object)
}

///|
pub impl @json.FromJson for Stopped with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Stopped raise @json.JsonDecodeError {
  guard json is Object(map) else {
    raise @json.JsonDecodeError(
      (json_path, "Stopped::from_json: expected object"),
    )
  }
  let name = match map.get("name") {
    None | Some(Null) => None
    Some(name_json) => Some(@json.from_json(name_json))
  }
  let id = match map.get("id") {
    Some(id_json) => @json.from_json(id_json, path=json_path.add_key("id"))
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("id"), "Stopped::from_json: missing 'id' field"),
      )
  }
  let cwd = match map.get("cwd") {
    Some(cwd_json) => @json.from_json(cwd_json, path=json_path.add_key("cwd"))
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("cwd"), "Stopped::from_json: missing 'cwd' field"),
      )
  }
  let created = match map.get("created") {
    Some(created_json) =>
      @json.from_json(created_json, path=json_path.add_key("created"))
    None =>
      raise @json.JsonDecodeError(
        (
          json_path.add_key("created"),
          "Stopped::from_json: missing 'created' field",
        ),
      )
  }
  let updated = match map.get("updated") {
    Some(updated_json) =>
      @json.from_json(updated_json, path=json_path.add_key("updated"))
    None =>
      raise @json.JsonDecodeError(
        (
          json_path.add_key("updated"),
          "Stopped::from_json: missing 'updated' field",
        ),
      )
  }
  let web_search = match map.get("web_search") {
    Some(web_search_json) =>
      @json.from_json(web_search_json, path=json_path.add_key("web_search"))
    None =>
      raise @json.JsonDecodeError(
        (
          json_path.add_key("web_search"),
          "Stopped::from_json: missing 'web_search' field",
        ),
      )
  }
  Stopped::{
    name,
    id,
    cwd,
    created,
    updated,
    web_search,
    broadcast: @broadcast.Broadcast::new(),
  }
}
