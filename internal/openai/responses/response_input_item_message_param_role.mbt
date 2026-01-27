///|
pub(all) enum ResponseInputItemMessageParamRole {
  User
  System
  Developer
} derive(Show)

///|
pub impl ToJson for ResponseInputItemMessageParamRole with to_json(
  self : ResponseInputItemMessageParamRole,
) -> Json {
  match self {
    User => "user"
    System => "system"
    Developer => "developer"
  }
}

///|
pub impl @json.FromJson for ResponseInputItemMessageParamRole with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemMessageParamRole raise @json.JsonDecodeError {
  guard json is String(role_str) else {
    raise @json.JsonDecodeError(
      (path, "ResponseInputItemMessageParamRole: expected string"),
    )
  }
  match role_str {
    "user" => User
    "system" => System
    "developer" => Developer
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseInputItemMessageParamRole: invalid role '\{role_str}'"),
      )
  }
}
