///|
struct ChatGenerationParamsPluginModeration {
  id : String
}

///|
pub impl ToJson for ChatGenerationParamsPluginModeration with to_json(
  self : ChatGenerationParamsPluginModeration,
) -> Json {
  let object : Map[String, Json] = {
    "type": "moderation",
    "id": self.id.to_json(),
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for ChatGenerationParamsPluginModeration with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsPluginModeration raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsPluginModeration::from_json"
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
  ChatGenerationParamsPluginModeration::{ id, }
}
