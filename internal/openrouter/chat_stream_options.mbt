///|
struct ChatStreamOptions {
  include_usage : Bool?
}

///|
pub impl ToJson for ChatStreamOptions with to_json(self : ChatStreamOptions) -> Json {
  let object : Map[String, Json] = {}
  if self.include_usage is Some(include_usage) {
    object["include_usage"] = include_usage.to_json()
  }
  Json::object(object)
}
