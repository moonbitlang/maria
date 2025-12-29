///|
/// Standard error object returned by the API.
pub struct ErrorObject {
  code : String
  message : String
  param : String
  type_ : String
}

///|
pub impl ToJson for ErrorObject with to_json(self : ErrorObject) -> Json {
  {
    "code": self.code,
    "message": self.message,
    "param": self.param,
    "type": self.type_,
  }
}

///|
pub impl @json.FromJson for ErrorObject with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ErrorObject raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let code : String = object.required("code", path~)
  let message : String = object.required("message", path~)
  let param : String = object.required("param", path~)
  let type_ : String = object.required("type", path~)
  ErrorObject::{ code, message, param, type_ }
}
