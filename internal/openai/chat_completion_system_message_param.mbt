///|
/// System message payload used to steer the assistant.
pub struct ChatCompletionSystemMessageParam {
  content : Array[ChatCompletionContentPartParam]
  name : String?
}
