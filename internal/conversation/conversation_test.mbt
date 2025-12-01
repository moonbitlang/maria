///|
async test "impl ToJson for Conversation" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @conversation.Manager::new(
      uuid=@uuid.generator(mock.rand),
      clock=mock.clock,
      cwd=mock.cwd.path(),
    )
    let conversation = manager.new_conversation(name="Test Conversation")
    conversation.set_system_prompt("This is a system prompt.")
    conversation.add_message(@ai.user_message(content="Hello"))
    @json.inspect(conversation, content={
      "name": "Test Conversation",
      "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
      "system_prompt": "This is a system prompt.",
      "messages": [
        { "timestamp": "2", "message": { "role": "user", "content": "Hello" } },
      ],
      "created_at": 0,
      "updated_at": 2,
    })
  })
}
