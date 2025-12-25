///|
/// Reason why the model stopped generating tokens.
pub(all) enum ChatCompletionChoiceFinishReason {
  Stop
  Length
  ToolCalls
  ContentFilter
  FunctionCall
} derive(Show)

///|
impl ToJson for ChatCompletionChoiceFinishReason with to_json(
  self : ChatCompletionChoiceFinishReason,
) -> Json {
  match self {
    Stop => "stop"
    Length => "length"
    ToolCalls => "tool_calls"
    ContentFilter => "content_filter"
    FunctionCall => "function_call"
  }
}

///|
impl @json.FromJson for ChatCompletionChoiceFinishReason with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChoiceFinishReason {
  guard json is String(reason) else {
    raise @json.JsonDecodeError((json_path, "Expected a string"))
  }
  match reason {
    "stop" => ChatCompletionChoiceFinishReason::Stop
    "length" => ChatCompletionChoiceFinishReason::Length
    "tool_calls" => ChatCompletionChoiceFinishReason::ToolCalls
    "content_filter" => ChatCompletionChoiceFinishReason::ContentFilter
    "function_call" => ChatCompletionChoiceFinishReason::FunctionCall
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Unknown finish reason: \{reason}"),
      )
  }
}
