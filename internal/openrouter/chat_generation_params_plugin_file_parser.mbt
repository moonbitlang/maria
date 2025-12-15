///|
struct ChatGenerationParamsPluginFileParser {
  id : String
  enabled : Bool?
  max_files : Int?
  pdf : ChatGenerationParamsPdf?
}

///|
pub impl ToJson for ChatGenerationParamsPluginFileParser with to_json(
  self : ChatGenerationParamsPluginFileParser,
) -> Json {
  let object : Map[String, Json] = {
    "type": "file_parser",
    "id": self.id.to_json(),
  }
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
