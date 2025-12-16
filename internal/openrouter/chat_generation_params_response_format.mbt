///|
enum ChatGenerationParamsResponseFormat {
  Text
  JSONObject
  JSONSchema(ResponseFormatJSONSchema)
  TextGrammar(ResponseFormatTextGrammar)
  Python
}

///|
pub impl ToJson for ChatGenerationParamsResponseFormat with to_json(
  self : ChatGenerationParamsResponseFormat,
) -> Json {
  match self {
    Text => "text"
    JSONObject => "json_object"
    JSONSchema(schema) => schema.to_json()
    TextGrammar(grammar) => grammar.to_json()
    Python => "python"
  }
}

///|
pub impl @json.FromJson for ChatGenerationParamsResponseFormat with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsResponseFormat raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsResponseFormat::from_json"
  match json {
    String(s) =>
      match s {
        "text" => ChatGenerationParamsResponseFormat::Text
        "json_object" => ChatGenerationParamsResponseFormat::JSONObject
        "python" => ChatGenerationParamsResponseFormat::Python
        _ =>
          raise @json.JsonDecodeError(
            (path, "\{func_name}: invalid value \"\{s}\""),
          )
      }
    Object({ "type": String(type_str), .. }) =>
      match type_str {
        "json_schema" =>
          ChatGenerationParamsResponseFormat::JSONSchema(
            @json.from_json(json, path~),
          )
        "text_grammar" =>
          ChatGenerationParamsResponseFormat::TextGrammar(
            @json.from_json(json, path~),
          )
        _ =>
          raise @json.JsonDecodeError(
            (path.add_key("type"), "\{func_name}: invalid type \"\{type_str}\""),
          )
      }
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: expect string or object"),
      )
  }
}
