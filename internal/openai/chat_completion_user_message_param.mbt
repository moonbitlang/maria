///|
/// User message payload sent to the model.
pub struct ChatCompletionUserMessageParam {
  content : Array[ChatCompletionContentPartParam]
  name : String?
}

///|
pub fn ChatCompletionUserMessageParam::new(
  content~ : Array[ChatCompletionContentPartParam],
  name? : String,
) -> ChatCompletionUserMessageParam {
  { content, name }
}
