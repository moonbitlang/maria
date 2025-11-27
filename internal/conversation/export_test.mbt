///|
async test "export_to_markdown" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @conversation.Manager::new(
      uuid=@uuid.generator(mock.rand),
      clock=mock.clock,
      cwd=mock.cwd.path(),
    )
    let conversation = manager.new_conversation(name="Test Conversation")
    conversation.add_message(@ai.user_message(content="Hello, how are you?"))
    conversation.add_message(
      @ai.assistant_message(content="I'm fine, thank you!"),
    )
    inspect(
      conversation.export_to_markdown(),
      content=(
        #|# Conversation: ac8a366d-ce7e-47d9-8bc7-27c69e416f1a
        #|
        #|**Name:** Test Conversation
        #|**Created:** 0
        #|**Updated:** 3
        #|**Messages:** 2
        #|
        #|## 👤 User
        #|
        #|### Content
        #|
        #|Hello, how are you?
        #|
        #|**Timestamp:** 2
        #|
        #|---
        #|
        #|## 🤖 Assistant
        #|
        #|### Content
        #|
        #|I'm fine, thank you!
        #|
        #|**Timestamp:** 3
      ),
    )
  })
}
