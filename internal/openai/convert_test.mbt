///|
test "message" {
  let openai_messages = []
  for
    message in [
      @ai.user_message(content="Hello"),
      @ai.system_message(content="You are a helpful assistant."),
      @ai.assistant_message(content="Here is the information you requested.", tool_calls=[
        @ai.tool_call(
          id="tool_call_1",
          name="fetch_data",
          arguments="{\"query\": \"latest news\"}",
        ),
      ]),
      @ai.tool_message(content="Tool output here.", tool_call_id="tool_call_1"),
    ] {
    openai_messages.push(
      @openai.ChatCompletionMessageParam::from_ai_message(message),
    )
  }
  @json.inspect(openai_messages, content=[
    { "role": "user", "content": "Hello" },
    { "role": "system", "content": "You are a helpful assistant." },
    {
      "role": "assistant",
      "tool_calls": [
        {
          "id": "tool_call_1",
          "function": {
            "name": "fetch_data",
            "arguments": "{\"query\": \"latest news\"}",
          },
          "type": "function",
        },
      ],
      "content": "Here is the information you requested.",
    },
    {
      "role": "tool",
      "content": [{ "type": "text", "text": "Tool output here." }],
      "tool_call_id": "tool_call_1",
    },
  ])
}

///|
test "ChatCompletionMessage::to_ai_message" {
  let openai_message : @openai.ChatCompletionMessage = @json.from_json({
    "role": "assistant",
    "content": "Hello, AI!",
    "tool_calls": [],
  })
  let ai_message = openai_message.to_ai_message()
  @json.inspect(ai_message.content(), content="Hello, AI!")
}

///|
test "usage" {
  let ai_usage = @ai.usage(
    input_tokens=150,
    output_tokens=350,
    cache_read_tokens=100,
  )
  let openai_usage = @openai.CompletionUsage::from_ai_usage(ai_usage)
  @json.inspect(openai_usage, content={
    "completion_tokens": 350,
    "prompt_tokens": 150,
    "prompt_tokens_details": { "cached_tokens": 100 },
    "total_tokens": 500,
  })
  let ai_usage = openai_usage.to_ai_usage()
  @json.inspect(ai_usage.input_tokens, content=150)
  @json.inspect(ai_usage.output_tokens, content=350)
  @json.inspect(ai_usage.total_tokens, content=500)
  @json.inspect(ai_usage.cache_read_tokens, content=[100])
}

///|
test "tool_call" {
  let ai_tool_call = @ai.tool_call(
    id="tool_call_1",
    name="fetch_data",
    arguments="{\"query\": \"latest news\"}",
  )
  let openai_tool_call = @openai.ChatCompletionMessageToolCall::from_ai_tool_call(
    ai_tool_call,
  )
  @json.inspect(openai_tool_call, content={
    "id": "tool_call_1",
    "function": {
      "name": "fetch_data",
      "arguments": "{\"query\": \"latest news\"}",
    },
    "type": "function",
  })
  @json.inspect(openai_tool_call.to_ai_tool_call().id, content="tool_call_1")
  @json.inspect(openai_tool_call.to_ai_tool_call().name, content="fetch_data")
  @json.inspect(openai_tool_call.to_ai_tool_call().arguments, content=[
    "{\"query\": \"latest news\"}",
  ])
  let tc_wo_args = @openai.tool_call(id="tool_call_1", name="fetch_data")
  @json.inspect(tc_wo_args.to_ai_tool_call().id, content="tool_call_1")
  @json.inspect(tc_wo_args.to_ai_tool_call().name, content="fetch_data")
  @json.inspect(tc_wo_args.to_ai_tool_call().arguments, content=null)
}

///|
test "tool_desc" {
  let tool_desc = @tool.tool_desc(
    name="fetch_data",
    description="Fetches the latest data based on a query.",
    schema=@tool.JsonSchema::from_json({
      "type": "object",
      "properties": {
        "query": {
          "type": "string",
          "description": "The search query to fetch data for.",
        },
      },
      "required": ["query"],
    }),
  )
  @json.inspect(@openai.ChatCompletionToolParam::from_tool_desc(tool_desc), content={
    "type": "function",
    "function": {
      "name": "fetch_data",
      "description": "Fetches the latest data based on a query.",
      "parameters": {
        "type": "object",
        "properties": {
          "query": {
            "type": "string",
            "description": "The search query to fetch data for.",
          },
        },
        "required": ["query"],
      },
    },
  })
}
