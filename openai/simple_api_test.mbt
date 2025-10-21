///|
const OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"

///|
fn gpt4o_mini(api_key : String) -> @model.Model {
  @model.new(
    api_key~,
    base_url=OPENROUTER_BASE_URL,
    name="openai/gpt-4o-mini",
    safe_zone_tokens=100000,
  )
}

///|
/// Test basic text completion
async test "text" {
  guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
    fail("OPENAI_API_KEY not set")
  }
  let model = gpt4o_mini(api_key)
  let response = text(model~, prompt="Say 'Hello, World!' and nothing else.")
  inspect(response.contains("Hello"), content="true")
}

///|
/// Test JSON response parsing
async test "json" {
  guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
    fail("OPENAI_API_KEY not set")
  }
  let model = gpt4o_mini(api_key)
  let response = json(
    model~,
    prompt="Return a JSON object with a 'message' field containing 'Hello, World!'. Wrap it in ```json```.",
  )
  guard response is { "message": String(message), .. } &&
    message.contains("Hello") else {
    fail("Expected JSON object")
  }
}

///|
/// Test basic chat completion
async test "chat" {
  guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
    fail("OPENAI_API_KEY not set")
  }
  let model = gpt4o_mini(api_key)
  let completion = chat(
    model~,
    chat_completion(
      model=model.name,
      messages=[
        system_message(content="You are a helpful assistant."),
        user_message(content="Say 'Hello' and nothing else."),
      ],
      max_tokens=50,
      temperature=0.7,
    ),
  )
  guard completion.choices
    is [{ message: { content: Some(content), .. }, .. }, ..] &&
    content.contains("Hello") else {
    fail("Expected choices with message content")
  }
}

///|
/// Test chat completion with usage tracking
async test "chat_with_usage" {
  guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
    fail("OPENAI_API_KEY not set")
  }
  let model = gpt4o_mini(api_key)
  let completion = chat(
    model~,
    chat_completion(
      model=model.name,
      messages=[
        system_message(content="You are a helpful assistant."),
        user_message(content="Say 'Hello' and nothing else."),
      ],
      max_tokens=50,
      temperature=0.7,
      usage=usage(include_=true),
    ),
  )
  guard completion.usage is Some(usage) else { fail("Expected usage data") }
  assert_true(usage.total_tokens > 0)
  assert_true(usage.prompt_tokens > 0)
  assert_true(usage.completion_tokens > 0)
}

///|
/// Test message construction helpers
test "message_helpers" {
  let sys_msg = system_message(content="You are a helpful assistant.")
  guard sys_msg is System(param) else { fail("Expected System message") }
  inspect(param.content.length() > 0, content="true")
  let user_msg = user_message(content="Hello", name="Alice")
  guard user_msg is User(param) else { fail("Expected User message") }
  inspect(param.content.length() > 0, content="true")
  guard param.name is Some(name) else { fail("Expected name") }
  inspect(name, content="Alice")
  let asst_msg = assistant_message(content="Hi there!")
  guard asst_msg is Assistant(param) else { fail("Expected Assistant message") }
  inspect(param.content.length() > 0, content="true")
}

///|
/// Test tool definition
test "tool_definition" {
  let tool_def = @openai.tool(
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
