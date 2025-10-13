///|
async test "impl ToJson for Conversation" (t : @test.T) {
  @taco.run(t, taco => {
    let manager = @conversation.Manager::new(
      uuid=@uuid.generator(taco.rand),
      clock=taco.clock,
      cwd=taco.cwd.path(),
    )
    let conversation = manager.new_conversation(name="Test Conversation")
    conversation.add_message(@openai.user_message(content="Hello"))
    @json.inspect(conversation, content={
      "name": "Test Conversation",
      "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
      "messages": [
        { "timestamp": "2", "message": { "role": "user", "content": "Hello" } },
      ],
      "created_at": 0,
      "updated_at": 2,
    })
  })
}
