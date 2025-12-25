///|
/// Roles that may appear in streamed completion deltas.
pub(all) enum ChatCompletionRole {
  Developer
  System
  User
  Assistant
  Tool
} derive(ToJson)

///|
impl @json.FromJson for ChatCompletionRole with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionRole {
  guard json is String(role) else {
    raise @json.JsonDecodeError((json_path, "Expected a string"))
  }
  match role {
    "developer" => Developer
    "system" => System
    "user" => User
    "assistant" => Assistant
    "tool" => Tool
    role => raise @json.JsonDecodeError((json_path, "Unknown role: \{role}"))
  }
}
