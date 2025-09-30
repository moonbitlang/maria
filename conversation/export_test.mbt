///|
fn strip_timestamp(content : String) -> String {
  let lines = content.split("\n").collect()
  let stripped = []
  for line in lines {
    if line.has_prefix("**Timestamp:**") {
      continue
    }
    if line.has_prefix("**Created:**") {
      continue
    }
    if line.has_prefix("**Updated:**") {
      continue
    }
    stripped.push(line)
  }
  return stripped.join("\n")
}

///|
test "export_to_markdown" {
  let conversation = @conversation.Conversation::new(
    name="Test Conversation",
    id=@conversation.Id::new(),
  )
  conversation.add_message(@openai.user_message(content="Hello, how are you?"))
  conversation.add_message(
    @openai.assistant_message(content="I'm fine, thank you!"),
  )
  inspect(
    strip_timestamp(conversation.export_to_markdown())
    .split("\n")
    .drop(2)
    .collect()
    .join("\n"),
    content=(
      #|**Name:** Test Conversation
      #|**Messages:** 2
      #|
      #|## 👤 User
      #|
      #|### Content
      #|
      #|Hello, how are you?
      #|
      #|
      #|---
      #|
      #|## 🤖 Assistant
      #|
      #|### Content
      #|
      #|I'm fine, thank you!
      #|
    ),
  )
}
