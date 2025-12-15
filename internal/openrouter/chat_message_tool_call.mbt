///|
enum ChatMessageToolCall {
  Function(ChatMessageToolCallFunction)
}

///|
pub impl ToJson for ChatMessageToolCall with to_json(self : ChatMessageToolCall) -> Json {
  match self {
    Function(func) => func.to_json()
  }
}
