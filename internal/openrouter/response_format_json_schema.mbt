///|
struct ResponseFormatJSONSchema {
  json_schema : String
}

///|
pub impl ToJson for ResponseFormatJSONSchema with to_json(
  self : ResponseFormatJSONSchema,
) -> Json {
  let object : Map[String, Json] = {
    "type": "json_schema",
    "json_schema": self.json_schema.to_json(),
  }
  Json::object(object)
}
