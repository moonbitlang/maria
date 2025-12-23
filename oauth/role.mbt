///|
pub(all) enum Role {
  User
  Assistant
  System
} derive(Show)

///|
pub impl ToJson for Role with to_json(self : Role) -> Json {
  match self {
    User => "user"
    Assistant => "assistant"
    System => "system"
  }
}

///|
pub impl @json.FromJson for Role with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Role raise @json.JsonDecodeError {
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "Role: expected string"))
  }
  match s {
    "user" => User
    "assistant" => Assistant
    "system" => System
    _ => raise @json.JsonDecodeError((path, "Role: invalid value '\{s}'"))
  }
}
