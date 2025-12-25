///|
pub(all) enum ChatGenerationParamsPlugin {
  Moderation
  Web(ChatGenerationParamsPluginWeb)
  FileParser(ChatGenerationParamsPluginFileParser)
  ResponseHealing(ChatGenerationParamsPluginResponseHealing)
}

///|
pub fn ChatGenerationParamsPlugin::new_moderation() -> ChatGenerationParamsPlugin {
  ChatGenerationParamsPlugin::Moderation
}

///|
pub fn ChatGenerationParamsPlugin::new_web(
  enabled? : Bool,
  max_results? : Int,
  search_prompt? : String,
  engine? : ChatGenerationParamsEngine,
) -> ChatGenerationParamsPlugin {
  let web_plugin = ChatGenerationParamsPluginWeb::new(
    enabled?,
    max_results?,
    search_prompt?,
    engine?,
  )
  ChatGenerationParamsPlugin::Web(web_plugin)
}

///|
pub fn ChatGenerationParamsPlugin::new_file_parser(
  enabled? : Bool,
  max_files? : Int,
  pdf? : ChatGenerationParamsPdf,
) -> ChatGenerationParamsPlugin {
  let parser_plugin = ChatGenerationParamsPluginFileParser::new(
    enabled?,
    max_files?,
    pdf?,
  )
  ChatGenerationParamsPlugin::FileParser(parser_plugin)
}

///|
pub fn ChatGenerationParamsPlugin::new_response_healing(
  enabled? : Bool,
) -> ChatGenerationParamsPlugin {
  let healing_plugin = ChatGenerationParamsPluginResponseHealing::new(enabled?)
  ChatGenerationParamsPlugin::ResponseHealing(healing_plugin)
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
  guard json is Object({ "id": String(id_str), .. }) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object with type"))
  }
  match id_str {
    "moderation" => ChatGenerationParamsPlugin::Moderation
    "web" => ChatGenerationParamsPlugin::Web(@json.from_json(json, path~))
    "file_parser" =>
      ChatGenerationParamsPlugin::FileParser(@json.from_json(json, path~))
    "response-healing" =>
      ChatGenerationParamsPlugin::ResponseHealing(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("id"), "\{func_name}: unknown id \"\{id_str}\""),
      )
  }
}
