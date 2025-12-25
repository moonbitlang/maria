///|
struct ChatMessageContentItemText {
  text : String
  cache_control : ChatMessageContentItemCacheControl?
}

///|
pub impl ToJson for ChatMessageContentItemText with to_json(
  self : ChatMessageContentItemText,
) -> Json {
  let object : Map[String, Json] = {
    "type": "text",
    "text": self.text.to_json(),
  }
  if self.cache_control is Some(cache_control) {
    object["cache_control"] = cache_control.to_json()
  }
  object.to_json()
}

///|
pub impl @json.FromJson for ChatMessageContentItemText with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatMessageContentItemText raise @json.JsonDecodeError {
  guard json is Object(object) else {
    raise @json.JsonDecodeError(
      (json_path, "\{PackageName}.ChatMessageContentItemText: expect object"),
    )
  }
  let text : String = match object.get("text") {
    Some(text_json) =>
      @json.from_json(text_json, path=json_path.add_key("text"))
    None =>
      raise @json.JsonDecodeError(
        (
          json_path.add_key("text"),
          "\{PackageName}.ChatMessageContentItemText: missing required field 'text'",
        ),
      )
  }
  let cache_control : ChatMessageContentItemCacheControl? = match
    object.get("cache_control") {
    None | Some(Null) => None
    Some(cache_control_json) =>
      Some(
        @json.from_json(
          cache_control_json,
          path=json_path.add_key("cache_control"),
        ),
      )
  }
  ChatMessageContentItemText::{ text, cache_control }
}
