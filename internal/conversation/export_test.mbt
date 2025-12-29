///|
async test "export_to_markdown" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @conversation.Manager::new(
      uuid=mock.uuid,
      clock=mock.clock,
      home=mock.cwd.path(),
    )
    let conversation = manager.new_conversation(
      name="Test Conversation",
      cwd=mock.cwd.path(),
    )
    let event_target = @event.EventTarget::new(uuid=mock.uuid)
    event_target.add_listener(event => conversation.add_event(event))
    event_target.emit(UserMessage("Hello, how are you?"))
    event_target.emit(
      AssistantMessage(usage=None, "I'm fine, thank you!", tool_calls=[]),
    )
    event_target.emit(UserMessage("What's the weather today?"))
    event_target.emit(
      AssistantMessage(usage=None, "I'll use the weather tool to check.", tool_calls=[
        @ai.tool_call(
          id="tc_0",
          name="get_weather",
          arguments="{\"location\":\"San Francisco\"}",
        ),
      ]),
    )
    event_target.flush()
    inspect(
      conversation.export_to_markdown(),
      content=(
        #|# Conversation: ac8a366d-ce7e-47d9-8bc7-27c69e416f1a
        #|
        #|**Name:** Test Conversation
        #|**Created:** 1970-01-01T00:00:00Z
        #|**Updated:** 1970-01-01T00:00:00Z
        #|**Messages:** 4
        #|
        #|## 👤 User
        #|
        #|### Content
        #|
        #|Hello, how are you?
        #|
        #|---
        #|
        #|## 🤖 Assistant
        #|
        #|### Content
        #|
        #|I'm fine, thank you!
        #|
        #|---
        #|
        #|## 👤 User
        #|
        #|### Content
        #|
        #|What's the weather today?
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
      ),
    )
  })
}
