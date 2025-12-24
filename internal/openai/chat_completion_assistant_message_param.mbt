///|
/// Assistant message payload in request parameters.
pub struct ChatCompletionAssistantMessageParam {
  content : Array[ChatCompletionContentPartParam]
  name : String?
  tool_calls : Array[ChatCompletionMessageToolCallParam]
}
