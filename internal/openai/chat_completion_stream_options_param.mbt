///|
pub struct ChatCompletionStreamOptionsParam {
  include_obfuscation : Bool?
  include_usage : Bool?
}

///|
pub impl ToJson for ChatCompletionStreamOptionsParam with to_json(
  self : ChatCompletionStreamOptionsParam,
) -> Json {
  let json : Map[String, Json] = {}
  if self.include_obfuscation is Some(include_obfuscation) {
    json["include_obfuscation"] = include_obfuscation.to_json()
  }
  if self.include_usage is Some(include_usage) {
    json["include_usage"] = include_usage.to_json()
  }
  Json::object(json)
}
