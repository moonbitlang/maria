///|
async test "export_to_markdown" (t : @test.Test) {
  @mock.run(t, taco => {
    let manager = @conversation.Manager::new(
      uuid=@uuid.generator(taco.rand),
      clock=taco.clock,
      cwd=taco.cwd.path(),
    )
    let conversation = manager.new_conversation(name="Test Conversation")
    conversation.add_message(
      @openai.user_message(content="Hello, how are you?"),
    )
    conversation.add_message(
      @openai.assistant_message(content="I'm fine, thank you!"),
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
