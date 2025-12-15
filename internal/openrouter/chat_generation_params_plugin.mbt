///|
enum ChatGenerationParamsPlugin {
  Moderation
  Web(ChatGenerationParamsPluginWeb)
  FileParser(ChatGenerationParamsPluginFileParser)
  ResponseHealing(ChatGenerationParamsPluginResponseHealing)
}

///|
pub impl ToJson for ChatGenerationParamsPlugin with to_json(
  self : ChatGenerationParamsPlugin,
) -> Json {
  match self {
    Moderation => {
      let obj : Map[String, Json] = { "type": "moderation" }
      Json::object(obj)
    }
    Web(web) => web.to_json()
    FileParser(parser) => parser.to_json()
    ResponseHealing(healing) => healing.to_json()
  }
}
