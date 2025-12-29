///|
/// A text input to the model.
pub struct ResponseInputText {
  text : String
}

///|
pub impl ToJson for ResponseInputText with to_json(self : ResponseInputText) -> Json {
  { "text": self.text, "type": "input_text" }
}

///|
pub impl @json.FromJson for ResponseInputText with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputText raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let text : String = object.required("text", path~)
  let _ : String = object.required("type", path~)
  ResponseInputText::{ text, }
}
