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
    id=@conversation.Id::new(rand=@rand.chacha8()),
  )
  conversation.add_message(@openai.user_message(content="Hello, how are you?"))
  conversation.add_message(
    @openai.assistant_message(content="I'm fine, thank you!"),
  )
  inspect(
    strip_timestamp(conversation.export_to_markdown()),
    content=(
      #|# Conversation: b773b606-3d46-46a5-8160-af22a66abc3c
      #|
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
