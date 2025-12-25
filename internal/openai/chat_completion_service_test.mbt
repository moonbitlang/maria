///|
async test "ChatCompletionService::create" (t : @test.Test) {
  @mock.run(t, mock => {
    let openai = @openai.OpenAI::new(api_key=mock.getenv("OPENAI_API_KEY"))
    let response = openai.chat.completion.create(model="gpt-4o", [
      @openai.user_message(content="Hello!"),
    ])
    guard response.choices is [choice, ..] else {
      fail("expected at least one choice")
    }
    guard choice.message.content is Some(content) else {
      fail("expected message content")
    }
    assert_false(content.is_empty())
  })
}
