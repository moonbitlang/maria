///|
async test "attempt_completion" (t : @test.Test) {
  @mock.run(t, _ => {
    let result = Ref::new(None)
    let tool = @attempt_completion.new(result)
    @json.inspect(tool.call({ "result": "This is the final result." }), content=[
      "Ok", "Task result created.",
    ])
    @json.inspect(result.val, content=["This is the final result."])
  })
}

///|
async test "attempt_completion/agentic" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let result = Ref::new(None)
    let agent = @agent.new(model, cwd=mock.cwd.path(), uuid=mock.uuid)
    agent.add_tool(@attempt_completion.new(result))
    agent.add_message(
      @openai.user_message(
        content=(
          #|Can you please call the <attempt_completion/> tool with result "Hello"?
        ),
      ),
    )
    agent.start()
    @json.inspect(result.val.map(result => result.contains("Hello")), content=[
      true,
    ])
  })
}
