///|
/// A message input to the model with a role indicating instruction hierarchy.
/// Instructions tagged as `developer` or `system` take precedence over `user`.
struct EasyInputMessageParam {
  /// Text, image, or audio input to the model, including prior assistant responses.
  content : EasyInputMessageContentParam
  /// The role of this message input. One of `user`, `assistant`, `system`, or `developer`.
  role : EasyInputMessageRole
} derive(Show)

///|
pub impl ToJson for EasyInputMessageParam with to_json(
  self : EasyInputMessageParam,
) -> Json {
  { "role": self.role, "content": self.content }
}

///|
pub impl @json.FromJson for EasyInputMessageParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> EasyInputMessageParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let role : EasyInputMessageRole = object.required("role", path~)
  let content : EasyInputMessageContentParam = object.required("content", path~)
  EasyInputMessageParam::{ role, content }
}
