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

///|
pub impl @json.FromJson for ChatStreamOptions with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatStreamOptions raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatStreamOptions::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let include_usage : Bool? = match object.get("include_usage") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("include_usage")))
  }
  ChatStreamOptions::{ include_usage, }
}
