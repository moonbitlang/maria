///|
fn with_mock_server(
  group : @async.TaskGroup[Unit],
  handler : @httpx.Handler,
) -> @model.Model raise {
  let server = @httpx.Server::new("127.0.0.1", 0)
  group.spawn_bg(() => server.serve(handler), no_wait=true)
  @model.new(
    api_key="test-key",
    base_url="http://127.0.0.1:\{server.port()}",
    name="mock-model",
    safe_zone_tokens=100000,
  )
}

///|
async test "chat" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = with_mock_server(mock.group, (_, w) => {
      let body =
        #|{"id":"chatcmpl-mock","object":"chat.completion","created":1700000000,"model":"mock-model","choices":[{"index":0,"message":{"role":"assistant","content":"Hello"},"finish_reason":"stop"}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}
      w.write_header(200)
      w.write(body)
      w.close()
    })
    let completion = chat(
      model~,
      chat_completion(
        model=model.model_name,
        messages=[
          system_message(content="You are a helpful assistant."),
          user_message(content="Say hello."),
        ],
        max_tokens=50,
        temperature=0.7,
      ),
    )
    guard completion.choices[0].message.content is Some(content) else {
      fail("Expected message content")
    }
    json_inspect(content.contains("Hello"), content=true)
  })
}

///|
async test "chat_with_usage" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = with_mock_server(mock.group, (_, w) => {
      let body =
        #|{"id":"chatcmpl-mock","object":"chat.completion","created":1700000000,"model":"mock-model","choices":[{"index":0,"message":{"role":"assistant","content":"Hello"},"finish_reason":"stop"}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}
      w.write_header(200)
      w.write(body)
      w.close()
    })
    let completion = chat(
      model~,
      chat_completion(
        model=model.model_name,
        messages=[
          system_message(content="You are a helpful assistant."),
          user_message(content="Say hello."),
        ],
        usage=usage(include_=true),
        max_tokens=50,
        temperature=0.7,
      ),
    )
    guard completion.usage is Some(u) else { fail("Expected usage info") }
    json_inspect(u.prompt_tokens > 0, content=true)
    json_inspect(u.completion_tokens > 0, content=true)
    json_inspect(u.total_tokens > 0, content=true)
  })
}

///|
async test "text" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = with_mock_server(mock.group, (_, w) => {
      let body =
        #|{"id":"chatcmpl-mock","object":"chat.completion","created":1700000000,"model":"mock-model","choices":[{"index":0,"message":{"role":"assistant","content":"Hello, World!"},"finish_reason":"stop"}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}
      w.write_header(200)
      w.write(body)
      w.close()
    })
    let result = text(model~, prompt="Say hello.")
    json_inspect(result.contains("Hello"), content=true)
  })
}

///|
async test "json" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = with_mock_server(mock.group, (_, w) => {
      let body =
        #|{"id":"chatcmpl-mock","object":"chat.completion","created":1700000000,"model":"mock-model","choices":[{"index":0,"message":{"role":"assistant","content":"```json\n{\"message\": \"Hello, World!\"}\n```"},"finish_reason":"stop"}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}
      w.write_header(200)
      w.write(body)
      w.close()
    })
    let result = json(
      model~,
      prompt="Return a JSON object with a message field.",
    )
    guard result is { "message": String(msg), .. } else {
      fail("Expected JSON with message field")
    }
    json_inspect(msg.contains("Hello"), content=true)
  })
}

///|
async test "streaming" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = with_mock_server(mock.group, (_, w) => {
      w.header().set("Content-Type", "text/event-stream")
      w.write_header(200)
      w.write(
        "data: {\"id\":\"chatcmpl-1\",\"object\":\"chat.completion.chunk\",\"created\":1000,\"model\":\"mock-model\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":\"Hello\"},\"finish_reason\":null}]}\n\n",
      )
      w.flush()
      w.write(
        "data: {\"id\":\"chatcmpl-1\",\"object\":\"chat.completion.chunk\",\"created\":1000,\"model\":\"mock-model\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\", World!\"},\"finish_reason\":null}]}\n\n",
      )
      w.flush()
      w.write(
        "data: {\"id\":\"chatcmpl-1\",\"object\":\"chat.completion.chunk\",\"created\":1000,\"model\":\"mock-model\",\"choices\":[{\"index\":0,\"delta\":{},\"finish_reason\":\"stop\"}]}\n\n",
      )
      w.flush()
      w.write("data: [DONE]\n\n")
      w.flush()
      w.close()
    })
    let chat_completion = chat(
      model~,
      chat_completion(
        model=model.model_name,
        messages=[user_message(content="Say hello")],
        stream=true,
      ),
    )
    guard chat_completion.choices[0].message.content is Some(content) else {
      fail("Expected message content")
    }
    json_inspect(content.contains("Hello, World!"), content=true)
  })
}

///|
async test "streaming_tool_call" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = with_mock_server(mock.group, (_, w) => {
      w.header().set("Content-Type", "text/event-stream")
      w.write_header(200)
      w.write(
        "data: {\"id\":\"chatcmpl-2\",\"object\":\"chat.completion.chunk\",\"created\":1000,\"model\":\"mock-model\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"tool_calls\":[{\"index\":0,\"id\":\"call_001\",\"type\":\"function\",\"function\":{\"name\":\"get_weather\",\"arguments\":\"\"}}]},\"finish_reason\":null}]}\n\n",
      )
      w.flush()
      w.write(
        "data: {\"id\":\"chatcmpl-2\",\"object\":\"chat.completion.chunk\",\"created\":1000,\"model\":\"mock-model\",\"choices\":[{\"index\":0,\"delta\":{\"tool_calls\":[{\"index\":0,\"function\":{\"arguments\":\"{\\\"location\\\": \\\"San Francisco\\\"}\"}}]},\"finish_reason\":null}]}\n\n",
      )
      w.flush()
      w.write(
        "data: {\"id\":\"chatcmpl-2\",\"object\":\"chat.completion.chunk\",\"created\":1000,\"model\":\"mock-model\",\"choices\":[{\"index\":0,\"delta\":{},\"finish_reason\":\"tool_calls\"}]}\n\n",
      )
      w.flush()
      w.write("data: [DONE]\n\n")
      w.flush()
      w.close()
    })
    let chat_completion = chat(
      model~,
      chat_completion(
        model=model.model_name,
        messages=[user_message(content="What is the weather?")],
        stream=true,
      ),
    )
    let tool_calls = chat_completion.choices[0].message.tool_calls
    json_inspect(tool_calls[0].function.name, content="get_weather")
    guard tool_calls[0].function.arguments is Some(arguments) else {
      fail("Expected arguments")
    }
    json_inspect(@json.parse(arguments), content={ "location": "San Francisco" })
  })
}

///|
async test "streaming_parallel_tool_call" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = with_mock_server(mock.group, (_, w) => {
      w.header().set("Content-Type", "text/event-stream")
      w.write_header(200)
      w.write(
        "data: {\"id\":\"chatcmpl-3\",\"object\":\"chat.completion.chunk\",\"created\":1000,\"model\":\"mock-model\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"tool_calls\":[{\"index\":0,\"id\":\"call_001\",\"type\":\"function\",\"function\":{\"name\":\"get_weather\",\"arguments\":\"\"}},{\"index\":1,\"id\":\"call_002\",\"type\":\"function\",\"function\":{\"name\":\"get_weather\",\"arguments\":\"\"}}]},\"finish_reason\":null}]}\n\n",
      )
      w.flush()
      w.write(
        "data: {\"id\":\"chatcmpl-3\",\"object\":\"chat.completion.chunk\",\"created\":1000,\"model\":\"mock-model\",\"choices\":[{\"index\":0,\"delta\":{\"tool_calls\":[{\"index\":0,\"function\":{\"arguments\":\"{\\\"location\\\": \\\"San Francisco\\\"}\"}}]},\"finish_reason\":null}]}\n\n",
      )
      w.flush()
      w.write(
        "data: {\"id\":\"chatcmpl-3\",\"object\":\"chat.completion.chunk\",\"created\":1000,\"model\":\"mock-model\",\"choices\":[{\"index\":0,\"delta\":{\"tool_calls\":[{\"index\":1,\"function\":{\"arguments\":\"{\\\"location\\\": \\\"Boston\\\"}\"}}]},\"finish_reason\":null}]}\n\n",
      )
      w.flush()
      w.write(
        "data: {\"id\":\"chatcmpl-3\",\"object\":\"chat.completion.chunk\",\"created\":1000,\"model\":\"mock-model\",\"choices\":[{\"index\":0,\"delta\":{},\"finish_reason\":\"tool_calls\"}]}\n\n",
      )
      w.flush()
      w.write("data: [DONE]\n\n")
      w.flush()
      w.close()
    })
    let chat_completion = chat(
      model~,
      chat_completion(
        model=model.model_name,
        messages=[user_message(content="What is the weather?")],
        stream=true,
      ),
    )
    let tool_calls : Array[ChatCompletionMessageToolCall] = chat_completion.choices[0].message.tool_calls
    let tool_calls = tool_calls.map(tc => {
      guard tc.to_json() is Object(tc_object)
      tc_object.remove("id")
      if tc.function.arguments is Some(arguments) {
        let function = tc_object["function"]
        guard function is Object(function_object) else {
          fail("Expected function object")
        }
        function_object["arguments"] = @json.parse(arguments)
      }
      tc_object.to_json()
    })
    tool_calls.sort_by((a, b) => a.stringify().compare(b.stringify()))
    json_inspect(tool_calls, content=[
      {
        "function": {
          "name": "get_weather",
          "arguments": { "location": "Boston" },
        },
        "type": "function",
      },
      {
        "function": {
          "name": "get_weather",
          "arguments": { "location": "San Francisco" },
        },
        "type": "function",
      },
    ])
  })
}

///|
/// Test tool definition
test "tool_definition" {
  let tool_def = tool(
    name="get_weather",
    description="Get the current weather in a location",
    parameters={
      "type": "object",
      "properties": { "location": { "type": "string" } },
      "required": ["location"],
    },
  )
  let json = tool_def.to_json()
  guard json is { "type": "function", "function": _, .. } else {
    fail("Expected JSON object")
  }
}

///|
/// Test response format helpers
test "response_format" {
  let text_format = ResponseFormat::Text
  let json = text_format.to_json()
  guard json is Object(obj) else { fail("Expected JSON object") }
  guard obj.get("type") is Some(String("text")) else {
    fail("Expected type 'text'")
  }
  let json_schema_format = json_schema(name="test_schema", schema={
    "type": "object",
    "properties": { "message": { "type": "string" } },
  })
  let json = json_schema_format.to_json()
  guard json is { "type": "json_schema", .. } else {
    fail("Expected JSON object")
  }
}

///|
#skip
async test "deepseek" {
  guard @os.getenv("DEEPSEEK_API_KEY") is Some(api_key) else {
    fail("DEEPSEEK_API_KEY not set")
  }
  let model = @model.new(
    api_key~,
    base_url="https://api.deepseek.com",
    name="deepseek-chat",
    safe_zone_tokens=128_000,
  )
  let completion = chat(
    model~,
    chat_completion(
      model=model.model_name,
      messages=[
        system_message(content="You are a helpful assistant."),
        user_message(content="Say 'Hello' and nothing else."),
      ],
      max_tokens=50,
      temperature=0.7,
    ),
  )
  guard completion.choices[0].message.content is Some(content) else {
    fail("Expected message content")
  }
  json_inspect(content.contains("Hello"), content=true)
}

///|
/// FIXME: Temporarily disabled due to Moonshot AI engine overload.
#cfg(false)
async test "kimi-k2" {
  guard @os.getenv("MOONSHOT_API_KEY") is Some(api_key) else {
    fail("MOONSHOT_API_KEY not set")
  }
  let model = @model.new(
    api_key~,
    base_url="https://api.moonshot.cn/v1",
    name="kimi-k2-turbo-preview",
    safe_zone_tokens=262_144,
  )
  let completion = chat(
    model~,
    chat_completion(
      model=model.model_name,
      messages=[
        system_message(content="You are a helpful assistant."),
        user_message(content="Say 'Hello' and nothing else."),
      ],
      max_tokens=50,
      temperature=0.7,
    ),
  )
  guard completion.choices[0].message.content is Some(content) else {
    fail("Expected message content")
  }
  json_inspect(content.contains("Hello"), content=true)
}

///|
#skip
async test "dashscope" {
  guard @os.getenv("DASHSCOPE_API_KEY") is Some(api_key) else {
    fail("DASHSCOPE_API_KEY not set")
  }
  let model = @model.new(
    api_key~,
    base_url="https://dashscope.aliyuncs.com/compatible-mode/v1",
    name="qwen3-coder-plus",
    safe_zone_tokens=997_952,
  )
  let completion = chat(
    model~,
    chat_completion(
      model=model.model_name,
      messages=[
        system_message(content="You are a helpful assistant."),
        user_message(content="Say 'Hello' and nothing else."),
      ],
      max_tokens=50,
      temperature=0.7,
    ),
  )
  guard completion.choices[0].message.content is Some(content) else {
    fail("Expected message content")
  }
  json_inspect(content.contains("Hello"), content=true)
}
