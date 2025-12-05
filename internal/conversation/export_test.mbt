///|
async test "export_to_markdown" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @conversation.Manager::new(
      uuid=@uuid.generator(mock.rand),
      clock=mock.clock,
      home=mock.cwd.path(),
    )
    let conversation = manager.new_conversation(
      name="Test Conversation",
      cwd=mock.cwd.path(),
    )
    conversation.add_message(
      manager.new_message(@ai.user_message(content="Hello, how are you?")),
    )
    conversation.add_message(
      manager.new_message(@ai.assistant_message(content="I'm fine, thank you!")),
    )
    conversation.add_message(
      manager.new_message(@ai.user_message(content="What's the weather today?")),
    )
    conversation.add_message(
      manager.new_message(
        @ai.assistant_message(content="I'll use the weather tool to check.", tool_calls=[
          @ai.tool_call(
            id="tc_0",
            name="get_weather",
            arguments="{\"location\":\"San Francisco\"}",
          ),
        ]),
      ),
    )
    inspect(
      conversation.export_to_markdown(),
      content=(
        #|# Conversation: ac8a366d-ce7e-47d9-8bc7-27c69e416f1a
        #|
        #|**Name:** Test Conversation
        #|**Created:** 0
        #|**Updated:** 5
        #|**Messages:** 4
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
        #|
        #|---
        #|
        #|## 👤 User
        #|
        #|### Content
        #|
        #|What's the weather today?
        #|
        #|**Timestamp:** 4
        #|
        #|---
        #|
        #|## 🤖 Assistant
        #|
        #|### Content
        #|
        #|I'll use the weather tool to check.
        #|
        #|**🔧 Tool Call:** Execute get_weather (get_weather)
        #|
        #|**Parameters:**
        #|- **location:** San Francisco
        #|
        #|**Timestamp:** 5
      ),
    )
  })
}
