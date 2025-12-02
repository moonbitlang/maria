///|
async test "impl ToJson for Conversation" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @conversation.Manager::new(
      uuid=@uuid.generator(mock.rand),
      clock=mock.clock,
      cwd=mock.cwd.path(),
    )
    let conversation = manager.new_conversation(name="Test Conversation")
    conversation.set_system_prompt("This is a system prompt.")
    conversation.add_message(@ai.user_message(content="Hello"))
    @json.inspect(conversation, content={
      "name": "Test Conversation",
      "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
      "system_prompt": "This is a system prompt.",
      "messages": [
        { "timestamp": 2, "message": { "role": "user", "content": "Hello" } },
      ],
      "created_at": 0,
      "updated_at": 2,
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
    "created_at": 0,
    "updated_at": 2,
  }
  let conversation : @conversation.Conversation = @json.from_json(json)
  @json.inspect(
    conversation.messages(include_system=true).map(fn(m) { m.to_openai() }),
    content=[
      { "role": "system", "content": "This is a system prompt." },
      { "role": "user", "content": "Hello" },
    ],
  )
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
      { "timestamp": 2, "message": { "role": "user", "content": "Hello" } },
      {
        "timestamp": 3,
        "message": { "role": "assistant", "content": "Hi", "tool_calls": [] },
      },
      {
        "timestamp": 4,
        "message": { "role": "user", "content": "How are you?" },
      },
      {
        "timestamp": 5,
        "message": {
          "role": "assistant",
          "content": "Good, thanks!",
          "tool_calls": [],
        },
      },
    ],
    "created_at": 0,
    "updated_at": 5,
  }
  let conversation : @conversation.Conversation = @json.from_json(json)
  inspect(
    conversation.display().join("\n"),
    content=(
      #|Name: Test Conversation
      #|Messages: 4
      #|Created: 1970-01-01T00:00:00Z
      #|Updated: 1970-01-01T00:00:00Z
    ),
  )
  inspect(
    conversation.display(show_messages=true).join("\n"),
    content=(
      #|Name: Test Conversation
      #|0. [user]
      #|  Hello
      #|1. [assistant]
      #|  Hi
      #|2. [user]
      #|  How are you?
      #|3. [assistant]
      #|  Good, thanks!
      #|Created: 1970-01-01T00:00:00Z
      #|Updated: 1970-01-01T00:00:00Z
    ),
  )
}
