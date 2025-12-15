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
