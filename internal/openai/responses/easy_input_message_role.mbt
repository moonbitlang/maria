///|
/// The role of the message input.
pub(all) enum EasyInputMessageRole {
  User
  Assistant
  System
  Developer
} derive(Show)

///|
pub impl ToJson for EasyInputMessageRole with to_json(
  self : EasyInputMessageRole,
) -> Json {
  match self {
    User => "user"
    Assistant => "assistant"
    System => "system"
    Developer => "developer"
  }
}

///|
pub impl @json.FromJson for EasyInputMessageRole with from_json(
  json : Json,
  path : @json.JsonPath,
) -> EasyInputMessageRole raise @json.JsonDecodeError {
  guard json is String(role_str) else {
    raise @json.JsonDecodeError((path, "EasyInputMessageRole: expected string"))
  }
  match role_str {
    "user" => User
    "assistant" => Assistant
    "system" => System
    "developer" => Developer
    _ =>
      raise @json.JsonDecodeError(
        (path, "EasyInputMessageRole: invalid role '\{role_str}'"),
      )
  }
}
