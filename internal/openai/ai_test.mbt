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
