///|
struct ToolDefinitionJson {
  name : String
  description : String?
}

///|
pub impl ToJson for ToolDefinitionJson with to_json(self : ToolDefinitionJson) -> Json {
  let object : Map[String, Json] = { "name": self.name.to_json() }
  if self.description is Some(description) {
    object["description"] = description.to_json()
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for ToolDefinitionJson with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolDefinitionJson raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ToolDefinitionJson::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let name : String = match object.get("name") {
    Some(name_json) => @json.from_json(name_json, path=path.add_key("name"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("name"), "\{func_name}: missing field name"),
      )
  }
  let description : String? = match object.get("description") {
    None | Some(Null) => None
    Some(description_json) =>
      Some(@json.from_json(description_json, path=path.add_key("description")))
  }
  ToolDefinitionJson::{ name, description }
}
