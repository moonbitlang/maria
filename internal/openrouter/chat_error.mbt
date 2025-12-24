///|
pub enum ChatErrorCode {
  String(String)
  Number(Double)
}

///|
pub struct ChatError {
  code : ChatErrorCode
  message : String
  param : String?
  type_ : String?
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
