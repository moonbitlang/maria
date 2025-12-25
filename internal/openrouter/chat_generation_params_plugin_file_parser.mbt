///|
pub struct ChatGenerationParamsPluginFileParser {
  enabled : Bool?
  max_files : Int?
  pdf : ChatGenerationParamsPdf?
}

///|
pub fn ChatGenerationParamsPluginFileParser::new(
  enabled? : Bool,
  max_files? : Int,
  pdf? : ChatGenerationParamsPdf,
) -> ChatGenerationParamsPluginFileParser {
  ChatGenerationParamsPluginFileParser::{ enabled, max_files, pdf }
}

///|
pub impl ToJson for ChatGenerationParamsPluginFileParser with to_json(
  self : ChatGenerationParamsPluginFileParser,
) -> Json {
  let object : Map[String, Json] = { "id": "file_parser" }
  if self.enabled is Some(enabled) {
    object["enabled"] = enabled.to_json()
  }
  if self.max_files is Some(max_files) {
    object["max_files"] = max_files.to_json()
  }
  if self.pdf is Some(pdf) {
    object["pdf"] = pdf.to_json()
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for ChatGenerationParamsPluginFileParser with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsPluginFileParser raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsPluginFileParser::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let enabled : Bool? = match object.get("enabled") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("enabled")))
  }
  let max_files : Int? = match object.get("max_files") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("max_files")))
  }
  let pdf : ChatGenerationParamsPdf? = match object.get("pdf") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("pdf")))
  }
  ChatGenerationParamsPluginFileParser::{ enabled, max_files, pdf }
}
