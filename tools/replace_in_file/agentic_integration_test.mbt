///|
async test "replace_in_file/agentic" (t : @test.Test) {
  // TODO: add retries support
  @mock.run(timeout=60_000, retry=3, t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    let file = mock.add_file(
      "file.txt",
      content=(
        #|line 1
        #|line 2
        #|line 3
        #|line 4
      ),
    )
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="Update line 2 in file.txt to say 'line 2 modified via agent'.",
    )
    agent.add_listener(event => {
      match event.desc {
        PostToolCall(tool_call, result~, rendered~) =>
          mock.logger.info("PostToolCall", data={
            "name": tool_call.name,
            "output": result,
            "text": rendered,
          })
        _ => ()
      }
    })
    agent.add_tool(@replace_in_file.new(manager))
    agent.start()
    inspect(
      file.read(),
      content=(
        #|line 1
        #|line 2 modified via agent
        #|line 3
        #|line 4
      ),
    )
  })
}
