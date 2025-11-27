///|
#skip
async test "@context.Extractor" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let extractor = @context.Extractor::new(
      model~,
      logger=mock.logger,
      safe_zone_tokens=2000,
    )
    let history : Array[@ai.Message] = [
      @ai.system_message(content="You are a helpful assistant."),
      @ai.user_message(
        content=(
          #|Can you please summarize the content in file README.md?
        ),
      ),
      @ai.assistant_message(
        content=(
          #|I need to see the project files to provide a summary.
        ),
        tool_calls=[
          @ai.tool_call(
            id="tool-call-0",
            name="read_file",
            arguments=Json::object({ "path": "README.md" }).stringify(indent=2),
          ),
        ],
      ),
    ]
    let content = @prompt.moonbit
    @json.inspect(
      extractor.extract_code_snippets(content, history~) is Some(_),
      content=true,
    )
  })
}
