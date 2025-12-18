///|
async test "impl ToJson for Conversation" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @conversation.Manager::new(
      uuid=@uuid.generator(mock.rand),
      clock=mock.clock,
      cwd=mock.cwd.path(),
    )
    let conversation = manager.new_conversation(name="Test Conversation")
    conversation.set_system_prompt(Some("This is a system prompt."))
    conversation.add_message(@ai.user_message(content="Hello"))
    @json.inspect(mock.json(conversation), content={
      "name": "Test Conversation",
      "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
      "system_prompt": "This is a system prompt.",
      "messages": [
        { "timestamp": 2, "message": { "role": "user", "content": "Hello" } },
      ],
      "created_at": 0,
      "updated_at": 2,
      "cwd": "(mock:cwd)",
    })
  })
}

///|
test "Conversation::FromJson" {
  let json : Json = {
    "name": "Test Conversation",
    "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
    "system_prompt": "This is a system prompt.",
    "messages": [
      { "timestamp": 2, "message": { "role": "user", "content": "Hello" } },
    ],
    "created_at": "0",
    "updated_at": "2",
    "cwd": "/home/user/project",
  }
  let conversation : @conversation.Conversation = @json.from_json(json)
  @json.inspect(conversation.messages().map(fn(m) { m.to_openai() }), content=[
    { "role": "system", "content": "This is a system prompt." },
    { "role": "user", "content": "Hello" },
  ])
  @json.inspect(
    conversation.messages(include_system=false).map(fn(m) { m.to_openai() }),
    content=[{ "role": "user", "content": "Hello" }],
  )
  @json.inspect(conversation.system_prompt(), content=[
    "This is a system prompt.",
  ])
}

///|
test "Conversation::display" {
  let json : Json = {
    "name": "Test Conversation",
    "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
    "system_prompt": "This is a system prompt.",
    "messages": [
      {
        "timestamp": 1,
        "message": { "role": "system", "content": "This is a system prompt." },
      },
      {
        "timestamp": 2,
        "message": { "role": "user", "content": "What time is it now" },
      },
      {
        "timestamp": 3,
        "message": {
          "role": "assistant",
          "content": "Hi",
          "tool_calls": [
            {
              "id": "tc0",
              "function": {
                "name": "execute_command",
                "arguments": Json::object({ "command": "date" }).stringify(),
              },
            },
          ],
        },
      },
      {
        "timestamp": 4,
        "message": {
          "role": "tool",
          "tool_call_id": "tc0",
          "content": "2024-01-01T12:00:00Z",
        },
      },
      {
        "timestamp": 5,
        "message": {
          "role": "assistant",
          "content": "Current time is 2024-01-01T12:00:00Z",
          "tool_calls": [],
        },
      },
    ],
    "created_at": "0",
    "updated_at": "5",
    "cwd": "/home/user/project",
  }
  let conversation : @conversation.Conversation = @json.from_json(json)
  inspect(
    conversation.display().join("\n"),
    content=(
      #|Name: Test Conversation
      #|Messages: 5
      #|Created: 1970-01-01T00:00:00Z
      #|Updated: 1970-01-01T00:00:00Z
    ),
  )
  inspect(
    conversation.display(show_messages=true).join("\n"),
    content=(
      #|Name: Test Conversation
      #|0. [system]
      #|  This is a system prompt.
      #|1. [user]
      #|  What time is it now
      #|2. [assistant]
      #|  Hi
      #|3. [tool]
      #|  2024-01-01T12:00:00Z
      #|4. [assistant]
      #|  Current time is 2024-01-01T12:00:00Z
      #|Created: 1970-01-01T00:00:00Z
      #|Updated: 1970-01-01T00:00:00Z
    ),
  )
}
