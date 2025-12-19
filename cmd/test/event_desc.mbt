///|
/// EventDesc describes the type and content of an event.
/// This type is used by cmd/jsonl2md to parse and convert JSONL logs to Markdown.
pub enum EventDesc {
  /// Event triggered when a model is loaded.
  ModelLoaded(name~ : String, model~ : @model.Model)
  /// Event triggered when the system prompt is being set.
  SystemPromptSet(String)
  Maria(@event.EventDesc)
}

///|
pub impl ToJson for EventDesc with to_json(self : EventDesc) -> Json {
  match self {
    ModelLoaded(name~, model~) =>
      { "msg": "ModelLoaded", "name": name, "model": model }
    SystemPromptSet(prompt) => { "msg": "SystemPromptSet", "prompt": prompt }
    Maria(event) => event.to_json()
  }
}

///|
pub impl @json.FromJson for EventDesc with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> EventDesc raise @json.JsonDecodeError {
  guard json is Object(object) else {
    raise @json.JsonDecodeError(
      (json_path, "EventDesc::from_json: expected object"),
    )
  }
  let msg : String = match object.get("msg") {
    Some(msg) => @json.from_json(msg)
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("msg"), "EventDesc::from_json: missing 'msg' field"),
      )
  }
  match msg {
    "ModelLoaded" => {
      let name : String = match object.get("name") {
        Some(name) => @json.from_json(name)
        None =>
          raise @json.JsonDecodeError(
            (
              json_path.add_key("name"),
              "EventDesc::from_json: missing 'name' field",
            ),
          )
      }
      let model : @model.Model = match object.get("model") {
        Some(model) => @json.from_json(model)
        None =>
          raise @json.JsonDecodeError(
            (
              json_path.add_key("model"),
              "EventDesc::from_json: missing 'model' field",
            ),
          )
      }
      ModelLoaded(name~, model~)
    }
    "SystemPromptSet" => {
      let prompt : String = match object.get("prompt") {
        Some(prompt) => @json.from_json(prompt)
        None =>
          raise @json.JsonDecodeError(
            (
              json_path.add_key("prompt"),
              "EventDesc::from_json: missing 'prompt' field",
            ),
          )
      }
      SystemPromptSet(prompt)
    }
    _ => Maria(@json.from_json(json, path=json_path))
  }
}
