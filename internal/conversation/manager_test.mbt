///|
async test "Manager" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @conversation.Manager::new(
      uuid=@uuid.generator(mock.rand),
      home=mock.cwd.path(),
    )
    @json.inspect(manager.list(), content=[])
    let dot_moonagent = @pathx.join(mock.cwd.path(), ".moonagent")
    @json.inspect(mock.json(@fsx.list_directory(dot_moonagent)), content=[
      {
        "path": "(mock:cwd)/.moonagent/conversations",
        "name": "conversations",
        "kind": "Directory",
      },
    ])
    let conversations = @pathx.join(dot_moonagent, "conversations")
    @json.inspect(mock.json(@fsx.list_directory(conversations)), content=[])
    let conversation = manager.new_conversation(
      name="Test Conversation",
      cwd=mock.cwd.path(),
    )
    conversation.add_message(@ai.user_message(content="Hello"))
    manager.save(conversation)
    @json.inspect(manager.list(), content=[
      "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
    ])
  })
}

///|
async test "Manager::load" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @conversation.Manager::new(
      uuid=mock.uuid,
      home=mock.cwd.path(),
      clock=mock.clock,
    )
    let conversation = manager.new_conversation(
      name="Test Conversation",
      cwd=mock.cwd.path(),
    )
    conversation.add_message(@ai.user_message(content="Hello"))
    @json.inspect(
      conversation.id(),
      content="ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
    )
    manager.save(conversation)
    let loaded = manager.load(
      @uuid.parse("ac8a366d-ce7e-47d9-8bc7-27c69e416f1a"),
    )
    @json.inspect(manager.load(@uuid.nil), content=null)
    @json.inspect(mock.json(loaded), content=[
      {
        "name": "Test Conversation",
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "messages": [
          { "timestamp": 2, "message": { "role": "user", "content": "Hello" } },
        ],
        "created_at": 0,
        "updated_at": 2,
        "cwd": "(mock:cwd)",
      },
    ])
  })
}
