///|
enum ChatCompletionFinishReason {
  ToolCalls
  Stop
  Length
  ContentFilter
  Error
}

///|
pub impl ToJson for ChatCompletionFinishReason with to_json(
  self : ChatCompletionFinishReason,
) -> Json {
  match self {
    ToolCalls => "tool_calls"
    Stop => "stop"
    Length => "length"
    ContentFilter => "content_filter"
    Error => "error"
  }
}
