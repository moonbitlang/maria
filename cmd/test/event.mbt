///|
/// Event represents a single event in the test session log.
/// This type is used by cmd/jsonl2md to parse and convert JSONL logs to Markdown.
pub struct Event {
  id : @uuid.Uuid
  desc : EventDesc
}

///|
pub impl ToJson for Event with to_json(self : Event) -> Json {
  { "id": self.id.to_json(), "desc": self.desc.to_json() }
}

///|
pub impl @json.FromJson for Event with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Event raise @json.JsonDecodeError {
  guard json is Object(object) else {
    raise @json.JsonDecodeError(
      (json_path, "Event::from_json: expected object"),
    )
  }
  let id : @uuid.Uuid = match object.get("id") {
    Some(id) => @json.from_json(id)
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("id"), "Event::from_json: missing 'id' field"),
      )
  }
  let desc : EventDesc = match object.get("desc") {
    Some(desc) => @json.from_json(desc)
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("desc"), "Event::from_json: missing 'desc' field"),
      )
  }
  { id, desc }
}
