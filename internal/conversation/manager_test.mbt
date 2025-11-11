///|
async test "Manager" (t : @test.Test) {
  @mock.run(t, taco => {
    let manager = @conversation.Manager::new(
      uuid=@uuid.generator(taco.rand),
      cwd=taco.cwd.path(),
    )
    @json.inspect(manager.list(), content=[])
    let dot_moonagent = @path.join(taco.cwd.path(), ".moonagent")
    @json.inspect(taco.json(@fsx.list_directory(dot_moonagent)), content=[
      {
        "path": "(mock:cwd)/.moonagent/conversations",
        "name": "conversations",
        "kind": "Directory",
      },
    ])
    let conversations = @path.join(dot_moonagent, "conversations")
    @json.inspect(taco.json(@fsx.list_directory(conversations)), content=[])
    let conversation = manager.new_conversation(name="Test Conversation")
    conversation.add_message(@openai.user_message(content="Hello"))
    manager.save(conversation)
    @json.inspect(manager.list(), content=[
      "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
    ])
  })
}
