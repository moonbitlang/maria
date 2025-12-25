///|
/// Response format preferences for the assistant output.
pub(all) enum ResponseFormat {
  Text
  JsonSchema(JsonSchema)
  JsonObject
}

///|
pub impl ToJson for ResponseFormat with to_json(self : ResponseFormat) -> Json {
  match self {
    Text => { "type": "text" }
    JsonSchema(json_schema) =>
      {
        "type": "json_schema",
        "json_schema": {
          let object : Map[String, Json] = {
            "name": Json::string(json_schema.name),
            "schema": json_schema.schema,
          }
          if json_schema.description is Some(description) {
            object["description"] = Json::string(description)
          }
          if json_schema.strict is Some(strict) {
            object["strict"] = Json::boolean(strict)
          }
          Json::object(object)
        },
      }
    JsonObject => { "type": "json_object" }
  }
}
