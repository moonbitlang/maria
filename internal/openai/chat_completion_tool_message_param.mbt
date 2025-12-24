///|
/// Tool message payload echoing tool outputs.
pub struct ChatCompletionToolMessageParam {
  content : Array[ChatCompletionContentPartParam]
  tool_call_id : String
}
