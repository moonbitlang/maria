///|
#skip
async test "queue_message" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = new(
      model,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
      logger=mock.logger,
      user_message="Hello.",
    )
    let _ = agent.queue_message(
      @ai.user_message(content="First queued message."),
    )
    json_inspect(
      json_inspect(agent.queued_messages(), content=[
        {
          "id": "42858c8d-3684-43ab-837d-ef6894a9b8dc",
          "message": { "role": "user", "content": "First queued message." },
          "web_search": false,
        },
      ]),
      content=null,
    )
    agent.start()
    json_inspect(agent.pending_queue.length(), content=0)
    json_inspect(agent.input_queue.length(), content=0)
  })
}
