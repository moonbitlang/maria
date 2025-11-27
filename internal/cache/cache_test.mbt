///|
test "no-system" {
  let messages = [
    @openai.user_message(content="Hello"),
    @openai.assistant_message(content="Hi, how can I help you?"),
    @openai.user_message(content="What's the weather like?"),
    @openai.assistant_message(content="The weather is sunny."),
  ]
  let cached = @cache.cache_messages(messages)
  @json.inspect(cached, content=[
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Hello",
          "cache_control": { "type": "ephemeral" },
        },
      ],
    },
    {
      "role": "assistant",
      "tool_calls": [],
      "content": "Hi, how can I help you?",
    },
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "What's the weather like?",
          "cache_control": { "type": "ephemeral" },
        },
      ],
    },
  ])
}

///|
test "single-system" {
  let messages = [
    @openai.system_message(content="You are a helpful assistant."),
  ]
  let cached = @cache.cache_messages(messages)
  @json.inspect(cached, content=[
    {
      "role": "system",
      "content": [
        {
          "type": "text",
          "text": "You are a helpful assistant.",
          "cache_control": { "type": "ephemeral" },
        },
      ],
    },
  ])
}

///|
test "multi-system" {
  let messages = [
    @openai.system_message(content="You are a helpful assistant."),
    @openai.system_message(content="You are also a funny assistant."),
  ]
  let cached = @cache.cache_messages(messages)
  @json.inspect(cached, content=[
    {
      "role": "system",
      "content": [
        {
          "type": "text",
          "text": "You are a helpful assistant.",
          "cache_control": { "type": "ephemeral" },
        },
      ],
    },
    {
      "role": "system",
      "content": [
        {
          "type": "text",
          "text": "You are also a funny assistant.",
          "cache_control": { "type": "ephemeral" },
        },
      ],
    },
  ])
}

///|
test "single-user" {
  let messages = [@openai.user_message(content="Hello")]
  let cached = @cache.cache_messages(messages)
  @json.inspect(cached, content=[
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Hello",
          "cache_control": { "type": "ephemeral" },
        },
      ],
    },
  ])
}

///|
test "single-tool" {
  let messages = [
    @openai.tool_message(content="Tool response", tool_call_id="tool_call_1"),
  ]
  let cached = @cache.cache_messages(messages)
  @json.inspect(cached, content=[
    {
      "role": "tool",
      "content": [
        {
          "type": "text",
          "text": "Tool response",
          "cache_control": { "type": "ephemeral" },
        },
      ],
      "tool_call_id": "tool_call_1",
    },
  ])
}

///|
test "system-single-user" {
  let messages = [
    @openai.system_message(content="You are a helpful assistant."),
    @openai.user_message(content="Hello"),
  ]
  let cached = @cache.cache_messages(messages)
  @json.inspect(cached, content=[
    {
      "role": "system",
      "content": [
        {
          "type": "text",
          "text": "You are a helpful assistant.",
          "cache_control": { "type": "ephemeral" },
        },
      ],
    },
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Hello",
          "cache_control": { "type": "ephemeral" },
        },
      ],
    },
  ])
}

///|
test "last-two" {
  let messages = [
    @openai.system_message(content="You are a helpful assistant."),
    @openai.user_message(content="Hello"),
    @openai.assistant_message(content="Hi, how can I help you?"),
    @openai.user_message(content="Can you tell me a joke?"),
    @openai.assistant_message(
      content="Sure! Why did the chicken cross the road?",
    ),
    @openai.user_message(
      content="That's funny! What's the weather like, by the way?",
    ),
    @openai.assistant_message(content="I need to call a tool."),
    @openai.tool_message(content="Tool response", tool_call_id="tool_call_1"),
  ]
  let cached = @cache.cache_messages(messages)
  @json.inspect(cached, content=[
    {
      "role": "system",
      "content": [
        {
          "type": "text",
          "text": "You are a helpful assistant.",
          "cache_control": { "type": "ephemeral" },
        },
      ],
    },
    { "role": "user", "content": "Hello" },
    {
      "role": "assistant",
      "tool_calls": [],
      "content": "Hi, how can I help you?",
    },
    { "role": "user", "content": "Can you tell me a joke?" },
    {
      "role": "assistant",
      "tool_calls": [],
      "content": "Sure! Why did the chicken cross the road?",
    },
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "That's funny! What's the weather like, by the way?",
          "cache_control": { "type": "ephemeral" },
        },
      ],
    },
    {
      "role": "assistant",
      "tool_calls": [],
      "content": "I need to call a tool.",
    },
    {
      "role": "tool",
      "content": [
        {
          "type": "text",
          "text": "Tool response",
          "cache_control": { "type": "ephemeral" },
        },
      ],
      "tool_call_id": "tool_call_1",
    },
  ])
}

///|
#skip
async test "caches-on-claude-sonnet-4.5" (t : @test.Test) {
  @mock.run(t, mock => {
    let uuid = @uuid.generator(@rand.chacha8())
    let cached_tokens = []
    let model = mock.model(name=ClaudeHaiku4_5)
    let messages = [
      @openai.system_message(
        content=(
          // Insert a randomly generated UUID to avoid cache hits from previous
          // test runs
          $|---
          $|id: \{uuid.v4()}
          $|---
          $|
          $|\{@prompt.moonbit}
        ),
      ),
      @openai.user_message(content="Hello"),
    ]
    // Make a request, record cached tokens, and append response to messages.
    async fn make_request() {
      let response = @openai.chat(
        model~,
        @openai.chat_completion(
          model=model.name,
          messages=@cache.cache_messages(messages),
          usage=@openai.usage(include_=true),
        ),
        extra_body={ "provider": { "only": ["anthropic"] } },
      )
      println(response.to_json().stringify(indent=2))
      if response.usage is Some(usage) &&
        usage.prompt_tokens_details is Some(details) &&
        details.cached_tokens is Some(count) {
        cached_tokens.push(count)
      }
      messages.push(response.choices[0].message.to_param())
    }

    make_request()
    messages.push(
      @openai.user_message(content="Please tell me what MoonBit is?"),
    )
    make_request()
    messages.push(@openai.user_message(content="Thank you!"))
    make_request()
    @json.inspect(cached_tokens.length(), content=3)
    // First request should have 0 cached tokens, as we used a unique UUID
    // in system prompt to avoid cache hits.
    @json.inspect(cached_tokens[0], content=0)
    // Second request should cache the system prompt and the first user message.
    @json.inspect(cached_tokens[1] > 0, content=true)
    // Third request should additionally cached the second user message, thus a
    // greater number of cached tokens than the second request.
    @json.inspect(cached_tokens[2] > cached_tokens[1], content=true)
  })
}
