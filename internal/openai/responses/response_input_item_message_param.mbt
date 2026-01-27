///|
struct ResponseInputItemMessageParam {
  /// A list of one or many input items to the model, supporting multiple content types.
  content : ResponseInputMessageContentListParam
  /// The role of the message input. One of `user`, `system`, or `developer`.
  role : ResponseInputItemMessageParamRole
  /// The status of the message input. One of `in_progress`, `completed`, or `incomplete`.
  status : ResponseInputItemMessageParamStatus?
} derive(Show)

///|
pub impl ToJson for ResponseInputItemMessageParam with to_json(
  self : ResponseInputItemMessageParam,
) -> Json {
  let object : Map[String, Json] = {
    "role": self.role,
    "content": self.content,
  }
  if self.status is Some(status) {
    object["status"] = status.to_json()
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for ResponseInputItemMessageParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemMessageParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let role : ResponseInputItemMessageParamRole = object.required("role", path~)
  let content : ResponseInputMessageContentListParam = object.required(
    "content",
    path~,
  )
  let status : ResponseInputItemMessageParamStatus? = object.optional(
    "status",
    path~,
  )
  ResponseInputItemMessageParam::{ content, role, status }
}
