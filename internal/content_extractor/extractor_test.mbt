///|
#skip
async test "@context.Extractor" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let extractor = @content_extractor.Extractor::new(
      model~,
      logger=mock.logger,
      safe_zone_tokens=2000,
    )
    let history : Array[@openai.ChatCompletionMessageParam] = [
      @openai.system_message(content="You are a helpful assistant."),
      @openai.user_message(
        content=(
          #|Can you please summarize the content in file README.md?
        ),
      ),
      @openai.assistant_message(
        content=(
          #|I need to see the project files to provide a summary.
        ),
        tool_calls=[
          @openai.tool_call(
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
