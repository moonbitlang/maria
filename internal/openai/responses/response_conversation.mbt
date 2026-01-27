///|
/// The conversation that this response belongs to.
pub struct ResponseConversation {
  id : String
}

///|
pub impl ToJson for ResponseConversation with to_json(
  self : ResponseConversation,
) -> Json {
  { "id": self.id }
}

///|
pub impl @json.FromJson for ResponseConversation with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseConversation raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  ResponseConversation::{ id, }
}
