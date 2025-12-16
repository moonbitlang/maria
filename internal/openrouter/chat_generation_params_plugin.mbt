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

///|
pub impl @json.FromJson for ChatGenerationParamsPlugin with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsPlugin raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsPlugin::from_json"
  guard json is Object({ "type": String(type_str), .. }) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object with type"))
  }
  match type_str {
    "moderation" =>
      // Some payloads are just {"type":"moderation"}, others include id.
      if json is Object({ "id": _, .. }) {
        ChatGenerationParamsPlugin::Moderation
      } else {
        ChatGenerationParamsPlugin::Moderation
      }
    "web" => ChatGenerationParamsPlugin::Web(@json.from_json(json, path~))
    "file_parser" =>
      ChatGenerationParamsPlugin::FileParser(@json.from_json(json, path~))
    "response-healing" =>
      ChatGenerationParamsPlugin::ResponseHealing(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("type"), "\{func_name}: unknown type \"\{type_str}\""),
      )
  }
}
