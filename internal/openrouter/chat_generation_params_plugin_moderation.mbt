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
