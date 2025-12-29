///|
/// A text input to the model.
pub struct ResponseInputText {
  text : String
  type_ : String
}

///|
pub impl ToJson for ResponseInputText with to_json(self : ResponseInputText) -> Json {
  { "text": self.text, "type": self.type_ }
}

///|
pub impl @json.FromJson for ResponseInputText with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputText raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let text : String = object.required("text", path~)
  let type_ : String = object.required("type", path~)
  ResponseInputText::{ text, type_ }
}
