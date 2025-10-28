///|
pub(all) struct JsonSchema(Json)

///|
pub fn JsonSchema::from_json(schema : Json) -> JsonSchema {
  JsonSchema(schema)
}

///|
pub fn JsonSchema::to_json(self : JsonSchema) -> Json {
  let JsonSchema(schema) = self
  schema
}
