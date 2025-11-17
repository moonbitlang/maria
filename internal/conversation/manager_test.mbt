///|
async test "Manager" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @conversation.Manager::new(
      uuid=@uuid.generator(mock.rand),
      cwd=mock.cwd.path(),
    )
    @json.inspect(manager.list(), content=[])
    let dot_moonagent = @path.join(mock.cwd.path(), ".moonagent")
    @json.inspect(mock.json(@fsx.list_directory(dot_moonagent)), content=[
      {
        "path": "(mock:cwd)/.moonagent/conversations",
        "name": "conversations",
        "kind": "Directory",
      },
    ])
    let conversations = @path.join(dot_moonagent, "conversations")
    @json.inspect(mock.json(@fsx.list_directory(conversations)), content=[])
    let conversation = manager.new_conversation(name="Test Conversation")
    conversation.add_message(@openai.user_message(content="Hello"))
    manager.save(conversation)
    @json.inspect(manager.list(), content=[
      "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
    ])
  })
}
