///|
struct ChatGenerationParamsPluginResponseHealing {
  id : String
  enabled : Bool?
}

///|
pub impl ToJson for ChatGenerationParamsPluginResponseHealing with to_json(
  self : ChatGenerationParamsPluginResponseHealing,
) -> Json {
  let object : Map[String, Json] = {
    "type": "response-healing",
    "id": self.id.to_json(),
  }
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
  let id : String = match object.get("id") {
    Some(v) => @json.from_json(v, path=path.add_key("id"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("id"), "\{func_name}: missing field id"),
      )
  }
  let enabled : Bool? = match object.get("enabled") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("enabled")))
  }
  ChatGenerationParamsPluginResponseHealing::{ id, enabled }
}
