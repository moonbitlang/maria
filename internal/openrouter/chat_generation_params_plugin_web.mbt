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

///|
pub impl @json.FromJson for ChatGenerationParamsPluginWeb with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsPluginWeb raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsPluginWeb::from_json"
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
  let max_results : Int? = match object.get("max_results") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("max_results")))
  }
  let search_prompt : String? = match object.get("search_prompt") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("search_prompt")))
  }
  let engine : ChatGenerationParamsEngine? = match object.get("engine") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("engine")))
  }
  ChatGenerationParamsPluginWeb::{
    id,
    enabled,
    max_results,
    search_prompt,
    engine,
  }
}
