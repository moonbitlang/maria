///|
struct ResponseErrorEvent {
  /// The error code.
  code : String
  /// The error message.
  message : String
  /// The error parameter.
  param : String
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseErrorEvent with to_json(self : ResponseErrorEvent) -> Json {
  {
    "type": "error",
    "code": self.code,
    "message": self.message,
    "param": self.param,
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseErrorEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseErrorEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let code : String = object.required("code", path~)
  let message : String = object.required("message", path~)
  let param : String = object.required("param", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseErrorEvent::{ code, message, param, sequence_number }
}
