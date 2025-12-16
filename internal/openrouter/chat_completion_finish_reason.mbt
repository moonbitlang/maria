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

///|
pub impl @json.FromJson for ChatCompletionFinishReason with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatCompletionFinishReason raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatCompletionFinishReason::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "tool_calls" => ChatCompletionFinishReason::ToolCalls
    "stop" => ChatCompletionFinishReason::Stop
    "length" => ChatCompletionFinishReason::Length
    "content_filter" => ChatCompletionFinishReason::ContentFilter
    "error" => ChatCompletionFinishReason::Error
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
