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
