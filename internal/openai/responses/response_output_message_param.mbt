///|
/// An output message from the model.
struct ResponseOutputMessageParam {
  /// The unique ID of the output message.
  id : String
  /// The content of the output message.
  content : ResponseOutputMessageContentListParam
  /// The status of the message input. One of `in_progress`, `completed`, or
  /// `incomplete`. Populated when input items are returned via API.
  status : ResponseOutputMessageStatus
  /// The role of the output message. Always `assistant`.
  role : ResponseOutputMessageParamRole
}

///|
pub impl ToJson for ResponseOutputMessageParam with to_json(
  self : ResponseOutputMessageParam,
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
pub impl @json.FromJson for ResponseOutputMessageParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputMessageParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let content : ResponseOutputMessageContentListParam = object.required(
    "content",
    path~,
  )
  let status : ResponseOutputMessageStatus = object.required("status", path~)
  let role : ResponseOutputMessageParamRole = object.required("role", path~)
  ResponseOutputMessageParam::{ id, content, status, role }
}
