///|
/// Plain text response format.
pub struct ResponseFormatText {
  type_ : String
}

///|
pub impl ToJson for ResponseFormatText with to_json(self : ResponseFormatText) -> Json {
  { "type": self.type_ }
}

///|
pub impl @json.FromJson for ResponseFormatText with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFormatText raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : String = object.required("type", path~)
  ResponseFormatText::{ type_, }
}

///|
/// JSON object response format.
pub struct ResponseFormatJSONObject {
  type_ : String
}

///|
pub impl ToJson for ResponseFormatJSONObject with to_json(
  self : ResponseFormatJSONObject,
) -> Json {
  { "type": self.type_ }
}

///|
pub impl @json.FromJson for ResponseFormatJSONObject with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFormatJSONObject raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : String = object.required("type", path~)
  ResponseFormatJSONObject::{ type_, }
}

///|
/// Structured Outputs configuration options, including a JSON Schema.
pub struct ResponseFormatJSONSchemaJSONSchema {
  name : String
  description : String?
  schema : Map[String, Json]
  strict : Bool?
}

///|
pub impl ToJson for ResponseFormatJSONSchemaJSONSchema with to_json(
  self : ResponseFormatJSONSchemaJSONSchema,
) -> Json {
  let obj : Map[String, Json] = { "name": self.name, "schema": self.schema }
  if self.description is Some(description) {
    obj["description"] = description.to_json()
  }
  if self.strict is Some(strict) {
    obj["strict"] = strict.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseFormatJSONSchemaJSONSchema with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFormatJSONSchemaJSONSchema raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let name : String = object.required("name", path~)
  let description : String? = object.optional("description", path~)
  let schema : Map[String, Json] = object.required("schema", path~)
  let strict : Bool? = object.optional("strict", path~)
  ResponseFormatJSONSchemaJSONSchema::{ name, description, schema, strict }
}

///|
/// JSON schema response format.
pub struct ResponseFormatJSONSchema {
  json_schema : ResponseFormatJSONSchemaJSONSchema
  type_ : String
}

///|
pub impl ToJson for ResponseFormatJSONSchema with to_json(
  self : ResponseFormatJSONSchema,
) -> Json {
  { "type": self.type_, "json_schema": self.json_schema }
}

///|
pub impl @json.FromJson for ResponseFormatJSONSchema with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFormatJSONSchema raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let json_schema : ResponseFormatJSONSchemaJSONSchema = object.required(
    "json_schema",
    path~,
  )
  let type_ : String = object.required("type", path~)
  ResponseFormatJSONSchema::{ json_schema, type_ }
}
