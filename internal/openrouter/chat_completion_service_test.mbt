///|
async test "chat.completion.create" (t : @test.Test) {
  @mock.run(t, mock => {
    let openrouter = @openrouter.OpenRouter::new(
      api_key=mock.getenv("OPENROUTER_API_KEY"),
    )
    let response = openrouter.chat.completion.create(
      model="anthropic/claude-haiku-4.5",
      messages=[@message.Message::new_user("Hello!")],
    )
    guard response.choices is [choice, ..] else {
      fail("expected at least one choice")
    }
    assert_false(choice.message.content.text().is_empty())
  })
}

///|
async test "chat.completion.create/provider" (t : @test.Test) {
  @mock.run(t, mock => {
    let openrouter = @openrouter.OpenRouter::new(
      api_key=mock.getenv("OPENROUTER_API_KEY"),
    )
    let response = openrouter.chat.completion.create(
      model="anthropic/claude-haiku-4.5",
      messages=[@message.Message::new_user("Hello!")],
      provider=@openrouter.ChatGenerationParamsProvider::new(only=[
        @provider.AmazonBedrock,
        @provider.Anthropic,
      ]),
    )
    guard response.choices is [choice, ..] else {
      fail("expected at least one choice")
    }
    assert_false(choice.message.content.text().is_empty())
  })
}

///|
async test "chat.completion.create/plugins" (t : @test.Test) {
  @mock.run(t, mock => {
    let openrouter = @openrouter.OpenRouter::new(
      api_key=mock.getenv("OPENROUTER_API_KEY"),
    )
    let response = openrouter.chat.completion.create(
      model="anthropic/claude-haiku-4.5",
      messages=[
        @message.Message::new_user("What's the weather like in New York?"),
      ],
      plugins=[
        @openrouter.ChatGenerationParamsPlugin::new_web(
          enabled=true,
          max_results=3,
        ),
      ],
    )
    guard response.choices is [choice, ..] else {
      fail("expected at least one choice")
    }
    assert_false(choice.message.content.text().is_empty())
  })
}

///|
async test "chat.completion.create/bad-request" (t : @test.Test) {
  @mock.run(t, mock => {
    let openrouter = @openrouter.OpenRouter::new(
      api_key=mock.getenv("OPENROUTER_API_KEY"),
    )
    let response = try? openrouter.chat.completion.create(
      model="nonexistent-model",
      messages=[@message.Message::new_user("Hello!")],
    )
    guard response is Err(_) else { fail("expected error response") }
  })
}

///|
async test "chat.completion.create/missing-api-key" (t : @test.Test) {
  @mock.run(t, _ => {
    let openrouter = @openrouter.OpenRouter::new(api_key="")
    let response = try? openrouter.chat.completion.create(
      model="anthropic/claude-haiku-4.5",
      messages=[@message.Message::new_user("Hello!")],
    )
    guard response is Err(_) else { fail("expected error response") }
  })
}
