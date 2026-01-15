///|
struct ResponseInputTextParam {
  /// The text input to send to the model.
  text : String
} derive(Show)

///|
impl ToJson for ResponseInputTextParam with to_json(
  self : ResponseInputTextParam,
) -> Json {
  { "text": self.text, "type": "text" }
}

///|
impl @json.FromJson for ResponseInputTextParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputTextParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let text : String = object.required("text", path~)
  ResponseInputTextParam::{ text, }
}
