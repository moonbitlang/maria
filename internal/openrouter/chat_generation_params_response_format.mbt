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
