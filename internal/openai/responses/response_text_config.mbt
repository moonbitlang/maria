///|
/// JSON Schema response format configuration.
pub struct ResponseFormatTextJSONSchemaConfig {
  name : String
  schema : Map[String, Json]
  description : String?
  strict : Bool?
}

///|
pub impl ToJson for ResponseFormatTextJSONSchemaConfig with to_json(
  self : ResponseFormatTextJSONSchemaConfig,
) -> Json {
  let obj : Map[String, Json] = {
    "name": self.name,
    "schema": self.schema,
    "type": "json_schema",
  }
  if self.description is Some(description) {
    obj["description"] = description.to_json()
  }
  if self.strict is Some(strict) {
    obj["strict"] = strict.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseFormatTextJSONSchemaConfig with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFormatTextJSONSchemaConfig raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let name : String = object.required("name", path~)
  let schema : Map[String, Json] = object.required("schema", path~)
  let _ : String = object.required("type", path~)
  let description : String? = object.optional("description", path~)
  let strict : Bool? = object.optional("strict", path~)
  ResponseFormatTextJSONSchemaConfig::{ name, schema, description, strict }
}

///|
/// Text response format configuration.
pub enum ResponseFormatTextConfig {
  Text(@shared.ResponseFormatText)
  JSONSchema(ResponseFormatTextJSONSchemaConfig)
  JSONObject(@shared.ResponseFormatJSONObject)
}

///|
pub impl ToJson for ResponseFormatTextConfig with to_json(
  self : ResponseFormatTextConfig,
) -> Json {
  match self {
    Text(value) => value.to_json()
    JSONSchema(value) => value.to_json()
    JSONObject(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseFormatTextConfig with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFormatTextConfig raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : String = object.required("type", path~)
  match type_ {
    "text" => Text(@json.from_json(json, path~))
    "json_schema" => JSONSchema(@json.from_json(json, path~))
    "json_object" => JSONObject(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseFormatTextConfig: invalid type '\{type_}'",
        ),
      )
  }
}

///|
/// Constrains the verbosity of the model's response.
pub enum ResponseTextConfigVerbosity {
  Low
  Medium
  High
}

///|
pub impl ToJson for ResponseTextConfigVerbosity with to_json(
  self : ResponseTextConfigVerbosity,
) -> Json {
  match self {
    Low => "low"
    Medium => "medium"
    High => "high"
  }
}

///|
pub impl @json.FromJson for ResponseTextConfigVerbosity with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseTextConfigVerbosity raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError(
      (path, "ResponseTextConfigVerbosity: expected string"),
    )
  }
  match value {
    "low" => Low
    "medium" => Medium
    "high" => High
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseTextConfigVerbosity: invalid value '\{value}'"),
      )
  }
}

///|
/// Configuration options for a text response from the model.
pub struct ResponseTextConfig {
  format : ResponseFormatTextConfig
  verbosity : ResponseTextConfigVerbosity?
}

///|
pub impl ToJson for ResponseTextConfig with to_json(self : ResponseTextConfig) -> Json {
  let obj : Map[String, Json] = { "format": self.format }
  if self.verbosity is Some(verbosity) {
    obj["verbosity"] = verbosity.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseTextConfig with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseTextConfig raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let format : ResponseFormatTextConfig = object.required("format", path~)
  let verbosity : ResponseTextConfigVerbosity? = object.optional(
    "verbosity",
    path~,
  )
  ResponseTextConfig::{ format, verbosity }
}
