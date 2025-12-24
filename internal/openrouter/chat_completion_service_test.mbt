///|
async test "chat.completion.create" (t : @test.Test) {
  @mock.run(t, mock => {
    let openrouter = @openrouter.OpenRouter::new(
      api_key=mock.getenv("OPENROUTER_API_KEY"),
    )
    let response = openrouter.chat.completion.create(
      model="anthropic/claude-haiku-4.5",
      messages=[@openrouter.Message::new_user("Hello!")],
    )
    guard response.choices is [choice, ..] else {
      fail("expected at least one choice")
    }
    assert_false(choice.message.content.text().is_empty())
  })
}
