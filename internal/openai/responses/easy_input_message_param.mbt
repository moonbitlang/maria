///|
struct EasyInputMessageParam {
  role : EasyInputMessageRole
  content : EasyInputMessageContentParam
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
