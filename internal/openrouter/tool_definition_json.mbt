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
