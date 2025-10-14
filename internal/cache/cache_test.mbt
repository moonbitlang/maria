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
