///|
struct ChatGenerationParamsPluginWeb {
  id : String
  enabled : Bool?
  max_results : Int?
  search_prompt : String?
  engine : ChatGenerationParamsEngine?
}

///|
pub impl ToJson for ChatGenerationParamsPluginWeb with to_json(
  self : ChatGenerationParamsPluginWeb,
) -> Json {
  let object : Map[String, Json] = { "type": "web", "id": self.id.to_json() }
  if self.enabled is Some(enabled) {
    object["enabled"] = enabled.to_json()
  }
  if self.max_results is Some(max_results) {
    object["max_results"] = max_results.to_json()
  }
  if self.search_prompt is Some(search_prompt) {
    object["search_prompt"] = search_prompt.to_json()
  }
  if self.engine is Some(engine) {
    object["engine"] = engine.to_json()
  }
  Json::object(object)
}
