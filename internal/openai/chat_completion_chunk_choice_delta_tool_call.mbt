///|
/// Partial tool call emitted in streaming deltas.
pub struct ChatCompletionChunkChoiceDeltaToolCall {
  index : Int
  id : String?
  function : ChatCompletionChunkChoiceDeltaToolCallFunction
} derive(ToJson)

///|
impl @json.FromJson for ChatCompletionChunkChoiceDeltaToolCall with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChunkChoiceDeltaToolCall {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("index") is Some(Number(index, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'index' field"))
  }
  let id = match json.get("id") {
    None | Some(Null) => None
    Some(String(id)) => Some(id)
    Some(_) =>
      raise @json.JsonDecodeError((json_path, "Expected 'id' to be a string"))
  }
  guard json.get("function") is Some(function) else {
    raise @json.JsonDecodeError((json_path, "Missing 'function' field"))
  }
  let function : ChatCompletionChunkChoiceDeltaToolCallFunction = @json.from_json(
    function,
    path=json_path.add_key("function"),
  )
  ChatCompletionChunkChoiceDeltaToolCall::{
    index: index.to_int(),
    id,
    function,
  }
}
