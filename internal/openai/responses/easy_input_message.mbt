///|
/// A message input to the model with a role indicating instruction hierarchy.
pub struct EasyInputMessage {
  content : EasyInputMessageContent
  role : EasyInputMessageRole
  type_ : String?
}

///|
/// Easy input message content union.
pub enum EasyInputMessageContent {
  Text(String)
  InputItemContentList(ResponseInputMessageContentList)
}

///|
pub impl ToJson for EasyInputMessageContent with to_json(
  self : EasyInputMessageContent,
) -> Json {
  match self {
    Text(value) => value.to_json()
    InputItemContentList(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for EasyInputMessageContent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> EasyInputMessageContent raise @json.JsonDecodeError {
  match json {
    String(value) => Text(value)
    Array(_) => InputItemContentList(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path, "EasyInputMessageContent: invalid value"),
      )
  }
}

///|
pub impl ToJson for EasyInputMessage with to_json(self : EasyInputMessage) -> Json {
  let obj : Map[String, Json] = { "content": self.content, "role": self.role }
  if self.type_ is Some(type_) {
    obj["type"] = type_.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for EasyInputMessage with from_json(
  json : Json,
  path : @json.JsonPath,
) -> EasyInputMessage raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let content : EasyInputMessageContent = object.required("content", path~)
  let role : EasyInputMessageRole = object.required("role", path~)
  let type_ : String? = object.optional("type", path~)
  EasyInputMessage::{ content, role, type_ }
}
