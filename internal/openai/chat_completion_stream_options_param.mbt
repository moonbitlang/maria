///|
pub struct ChatCompletionStreamOptionsParam {
  include_obfuscation : Bool?
  include_usage : Bool?
}

///|
pub impl ToJson for ChatCompletionStreamOptionsParam with fn to_json(
  self : ChatCompletionStreamOptionsParam,
) -> Json {
  let json : Map[String, Json] = Map([])
  if self.include_obfuscation is Some(include_obfuscation) {
    json["include_obfuscation"] = ToJson::to_json(include_obfuscation)
  }
  if self.include_usage is Some(include_usage) {
    json["include_usage"] = ToJson::to_json(include_usage)
  }
  Json::object(json)
}

///|
pub extend ChatCompletionStreamOptionsParam with ToJson::{to_json}
