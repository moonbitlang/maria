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

///|
pub impl @json.FromJson for ResponseFormatJSONSchema with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFormatJSONSchema raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ResponseFormatJSONSchema::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let json_schema : String = match object.get("json_schema") {
    Some(v) => @json.from_json(v, path=path.add_key("json_schema"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("json_schema"), "\{func_name}: missing field json_schema"),
      )
  }
  ResponseFormatJSONSchema::{ json_schema, }
}
