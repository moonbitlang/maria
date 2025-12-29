///|
/// JSON schema describing a callable function.
pub(all) struct FunctionDefinition {
  name : String
  description : String
  parameters : FunctionParameters
  strict : Bool?
}

///|
pub impl ToJson for FunctionDefinition with to_json(self : FunctionDefinition) -> Json {
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

///|
pub impl @json.FromJson for FunctionDefinition with from_json(
  json : Json,
  path : @json.JsonPath,
) -> FunctionDefinition raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let name : String = object.required("name", path~)
  let description : String = match object.optional("description", path~) {
    Some(description) => description
    None => ""
  }
  let parameters : FunctionParameters = match
    object.optional("parameters", path~) {
    Some(parameters) => parameters
    None => Json::object({})
  }
  let strict : Bool? = object.optional("strict", path~)
  FunctionDefinition::{ name, description, parameters, strict }
}
