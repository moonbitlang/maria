///|
/// Message author roles reflected in completion responses.
pub enum ChatCompletionMessageRole {
  Assistant
} derive(Show)

///|
pub impl ToJson for ChatCompletionMessageRole with to_json(
  self : ChatCompletionMessageRole,
) -> Json {
  match self {
    Assistant => "assistant"
  }
}
