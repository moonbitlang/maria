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
    @json.inspect(
      @json.inspect(agent.queued_messages(), content=[
        {
          "id": "f378dd8d-6f56-4e4d-8d63-4ff59e92f44c",
          "message": { "role": "user", "content": "First queued message." },
          "web_search": false,
        },
      ]),
      content=null,
    )
    agent.start()
    @json.inspect(agent.pending_queue.length(), content=0)
    @json.inspect(agent.input_queue.length(), content=0)
  })
}
