///|
/// JSON schema describing a callable function.
pub struct FunctionDefinition {
  name : String
  description : String
  parameters : Json
  strict : Bool?
}

///|
impl ToJson for FunctionDefinition with to_json(self : FunctionDefinition) -> Json {
  let json : Map[String, Json] = {
    "name": Json::string(self.name),
    "description": Json::string(self.description),
    "parameters": self.parameters,
  }
  if self.strict is Some(bool) {
    json["strict"] = Json::boolean(bool)
  }
  Json::object(json)
}
