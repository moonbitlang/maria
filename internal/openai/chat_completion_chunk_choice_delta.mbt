///|
/// Delta payload for a streamed chat completion chunk.
pub struct ChatCompletionChunkChoiceDelta {
  content : String?
  refusal : String?
  role : ChatCompletionRole?
  tool_calls : Array[ChatCompletionChunkChoiceDeltaToolCall]?
} derive(ToJson)

///|
impl @json.FromJson for ChatCompletionChunkChoiceDelta with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChunkChoiceDelta {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let content = match json.get("content") {
    Some(Null) => None
    Some(content) => {
      let content : String = @json.from_json(
        content,
        path=json_path.add_key("content"),
      )
      Some(content)
    }
    None => None
  }
  let refusal = match json.get("refusal") {
    Some(Null) => None
    Some(refusal) => {
      let refusal : String = @json.from_json(
        refusal,
        path=json_path.add_key("refusal"),
      )
      Some(refusal)
    }
    None => None
  }
  let role = match json.get("role") {
    Some(role) => {
      let role : ChatCompletionRole = @json.from_json(
        role,
        path=json_path.add_key("role"),
      )
      Some(role)
    }
    None => None
  }
  let tool_calls = match json.get("tool_calls") {
    Some(tool_calls) => {
      let tool_calls : Array[ChatCompletionChunkChoiceDeltaToolCall] = @json.from_json(
        tool_calls,
        path=json_path.add_key("tool_calls"),
      )
      Some(tool_calls)
    }
    None => None
  }
  ChatCompletionChunkChoiceDelta::{ content, refusal, role, tool_calls }
}
