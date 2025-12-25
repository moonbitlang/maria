///|
pub struct ChatGenerationParamsPluginResponseHealing {
  enabled : Bool?
}

///|
pub fn ChatGenerationParamsPluginResponseHealing::new(
  enabled? : Bool,
) -> ChatGenerationParamsPluginResponseHealing {
  ChatGenerationParamsPluginResponseHealing::{ enabled, }
}

///|
pub impl ToJson for ChatGenerationParamsPluginResponseHealing with to_json(
  self : ChatGenerationParamsPluginResponseHealing,
) -> Json {
  let object : Map[String, Json] = { "id": "response-healing" }
  if self.enabled is Some(enabled) {
    object["enabled"] = enabled.to_json()
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for ChatGenerationParamsPluginResponseHealing with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsPluginResponseHealing raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsPluginResponseHealing::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let enabled : Bool? = match object.get("enabled") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("enabled")))
  }
  ChatGenerationParamsPluginResponseHealing::{ enabled, }
}
