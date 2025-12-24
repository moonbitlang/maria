///|
/// Partial tool function payload emitted in streaming deltas.
pub struct ChatCompletionChunkChoiceDeltaToolCallFunction {
  arguments : String?
  name : String?
} derive(ToJson)

///|
impl @json.FromJson for ChatCompletionChunkChoiceDeltaToolCallFunction with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChunkChoiceDeltaToolCallFunction {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let arguments = match json.get("arguments") {
    None | Some(Null) => None
    Some(String(arguments)) => Some(arguments)
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'arguments' to be a string"),
      )
  }
  let name = match json.get("name") {
    None | Some(Null) => None
    Some(String(name)) => Some(name)
    Some(_) =>
      raise @json.JsonDecodeError((json_path, "Expected 'name' to be a string"))
  }
  ChatCompletionChunkChoiceDeltaToolCallFunction::{ arguments, name }
}
