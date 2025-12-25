///|
pub enum ChatErrorCode {
  String(String)
  Number(Double)
}

///|
pub impl ToJson for ChatErrorCode with to_json(self : ChatErrorCode) -> Json {
  match self {
    ChatErrorCode::String(s) => s.to_json()
    ChatErrorCode::Number(n) => n.to_json()
  }
}

///|
pub struct ChatError {
  code : ChatErrorCode
  message : String
  param : String?
  type_ : String?
}

///|
pub impl ToJson for ChatError with to_json(self : ChatError) -> Json {
  let object : Map[String, Json] = {
    "code": self.code.to_json(),
    "message": self.message.to_json(),
  }
  if self.param is Some(param) {
    object["param"] = param.to_json()
  }
  if self.type_ is Some(type_) {
    object["type"] = type_.to_json()
  }
  Json::object({ "error": object })
}

///|
pub impl @json.FromJson for ChatError with from_json(
  json : Json,
  path : @json.JsonPath,
) {
  let func_name = "\{PackageName}.ChatError::from_json"
  guard json is { "error": Object(object), .. } else {
    raise @json.JsonDecodeError(
      (path, "\{func_name}: expected object with 'error' field"),
    )
  }
  let path = path.add_key("error")
  let code = match object.get("code") {
    Some(String(code)) => ChatErrorCode::String(code)
    Some(Number(code, ..)) => ChatErrorCode::Number(code)
    Some(_) =>
      raise @json.JsonDecodeError(
        (path.add_key("code"), "\{func_name}: expected string or number"),
      )
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("code"), "\{func_name}: missing field 'code'"),
      )
  }
  let message : String = match object.get("message") {
    Some(String(message)) => message
    Some(_) =>
      raise @json.JsonDecodeError(
        (path.add_key("message"), "\{func_name}: expected string"),
      )
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("message"), "\{func_name}: missing field 'message'"),
      )
  }
  let param : String? = match object.get("param") {
    Some(String(param)) => Some(param)
    Some(_) =>
      raise @json.JsonDecodeError(
        (path.add_key("param"), "\{func_name}: expected string"),
      )
    None => None
  }
  let type_ : String? = match object.get("type") {
    Some(String(type_)) => Some(type_)
    Some(_) =>
      raise @json.JsonDecodeError(
        (path.add_key("type"), "\{func_name}: expected string"),
      )
    None => None
  }
  { code, message, param, type_ }
}

///|
pub suberror ChatCompletionError {
  BadRequest(ChatError)
  Unauthorized(ChatError)
  TooManyRequests(ChatError)
  InternalServerError(ChatError)
  UnknownError(Int, ChatError)
}

///|
pub impl ToJson for ChatCompletionError with to_json(self : ChatCompletionError) -> Json {
  match self {
    ChatCompletionError::BadRequest(error) => error.to_json()
    ChatCompletionError::Unauthorized(error) => error.to_json()
    ChatCompletionError::TooManyRequests(error) => error.to_json()
    ChatCompletionError::InternalServerError(error) => error.to_json()
    ChatCompletionError::UnknownError(_, error) => error.to_json()
  }
}
