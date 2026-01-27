///|
/// The role of the output message. Always `assistant`.
pub(all) enum ResponseOutputMessageParamRole {
  Assistant
} derive(Show)

///|
pub impl ToJson for ResponseOutputMessageParamRole with to_json(
  self : ResponseOutputMessageParamRole,
) -> Json {
  match self {
    Assistant => "assistant"
  }
}

///|
pub impl @json.FromJson for ResponseOutputMessageParamRole with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputMessageParamRole raise @json.JsonDecodeError {
  guard json is String(role_str) else {
    raise @json.JsonDecodeError(
      (path, "ResponseOutputMessageParamRole: expected string"),
    )
  }
  match role_str {
    "assistant" => Assistant
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseOutputMessageParamRole: invalid role '\{role_str}'"),
      )
  }
}
