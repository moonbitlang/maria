///|
/// TODO: add ChatCompletionMessageRole enum to openai package
fn openai_message_role(message : @ai.Message) -> String {
  match message {
    User(_) => "User"
    Assistant(_) => "Assistant"
    System(_) => "System"
    Tool(_) => "Tool"
  }
}

///|
/// TODO: move to openai package
fn openai_message_content(message : @ai.Message) -> String {
  message.content()
}
