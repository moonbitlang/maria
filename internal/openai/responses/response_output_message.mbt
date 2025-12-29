///|
/// an output message from the model.
pub struct ResponseOutputMessage {
  /// The unique ID of the output message.
  id : String
  /// The content of the output message.
  content : Array[ResponseOutputMessageContent]
  /// The status of the message input. One of `in_progress`, `completed`, or
  /// `incomplete`. Populated when input items are returned via API.
  status : ResponseOutputMessageStatus
  /// The role of the output message. Always `assistant`.
  role : ResponseOutputMessageParamRole
}

///|
pub impl ToJson for ResponseOutputMessage with to_json(
  self : ResponseOutputMessage,
) -> Json {
  {
    "type": "message",
    "id": self.id,
    "content": self.content,
    "status": self.status,
    "role": self.role,
  }
}

///|
pub impl @json.FromJson for ResponseOutputMessage with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputMessage raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let content : Array[ResponseOutputMessageContent] = object.required(
    "content",
    path~,
  )
  let status : ResponseOutputMessageStatus = object.required("status", path~)
  let role : ResponseOutputMessageParamRole = object.required("role", path~)
  ResponseOutputMessage::{ id, content, status, role }
}
