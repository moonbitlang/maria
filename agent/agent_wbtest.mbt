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
          "id": "1ea1417c-a31f-4b1b-8494-d8486add6aa4",
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
