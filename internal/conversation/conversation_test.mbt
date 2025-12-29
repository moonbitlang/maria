///|
async test "impl ToJson for Conversation" (t : @test.Test) {
  @mock.run(t, mock => {
    let home = mock.cwd
    let cwd = home.add_directory("cwd")
    let manager = @conversation.Manager::new(
      uuid=mock.uuid,
      clock=mock.clock,
      home=home.path(),
    )
    let conversation = manager.new_conversation(
      name="Test Conversation",
      cwd=cwd.path(),
    )
    let event_target = @event.EventTarget::new(uuid=mock.uuid)
    event_target.add_listener(event => conversation.add_event(event))
    conversation.set_system_prompt(Some("This is a system prompt."))
    event_target.emit(UserMessage("Hello"))
    event_target.flush()
    @json.inspect(
      mock.json(conversation).transform(@json.Replacer::exclude(["created"])),
      content={
        "name": "Test Conversation",
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "system_prompt": "This is a system prompt.",
        "events": [
          {
            "id": "1ea1417c-a31f-4b1b-8494-d8486add6aa4",
            "desc": { "msg": "UserMessage", "content": "Hello" },
          },
        ],
        "created_at": 0,
        "updated_at": 2,
        "cwd": "(mock:cwd)/cwd",
      },
    )
  })
}

///|
async test "Conversation::FromJson" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    let event_target = @event.EventTarget::new(uuid=mock.uuid)
    event_target.add_listener(event => events.push(event))
    event_target.emit(UserMessage("Hello"))
    event_target.flush()
    @json.inspect(
      events.to_json().transform(@json.Replacer::exclude(["created"])),
      content=[
        {
          "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
          "desc": { "msg": "UserMessage", "content": "Hello" },
        },
      ],
    )
    let json : Json = {
      "name": "Test Conversation",
      "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
      "system_prompt": "This is a system prompt.",
      "events": events,
      "created_at": "0",
      "updated_at": "2",
      "cwd": "/home/user/project",
    }
    let conversation : @conversation.Conversation = @json.from_json(json)
    @json.inspect(conversation.messages().map(fn(m) { m.to_openai() }), content=[
      { "role": "user", "content": "Hello" },
    ])
    @json.inspect(
      conversation.messages(include_system=false).map(fn(m) { m.to_openai() }),
      content=[{ "role": "user", "content": "Hello" }],
    )
    @json.inspect(conversation.system_prompt(), content=[
      "This is a system prompt.",
    ])
  })
}

///|
async test "Conversation::display" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    let event_target = @event.EventTarget::new(uuid=mock.uuid)
    event_target.add_listener(event => events.push(event))
    event_target.emit(UserMessage("What time is it now"))
    event_target.emit(
      AssistantMessage(usage=None, "Hi", tool_calls=[
        @ai.tool_call(
          id="tc0",
          name="execute_command",
          arguments="{\"command\":\"date\"}",
        ),
      ]),
    )
    event_target.emit(
      PostToolCall(
        @ai.tool_call(
          id="tc0",
          name="execute_command",
          arguments="{\"command\":\"date\"}",
        ),
        result=Ok("2024-01-01T12:00:00Z"),
        rendered="2024-01-01T12:00:00Z",
      ),
    )
    event_target.emit(
      AssistantMessage(usage=None, "Current time is 2024-01-01T12:00:00Z", tool_calls=[]),
    )
    event_target.flush()
    @json.inspect(
      events.to_json().transform(@json.Replacer::exclude(["created"])),
      content=[
        {
          "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
          "desc": { "msg": "UserMessage", "content": "What time is it now" },
        },
        {
          "id": "1ea1417c-a31f-4b1b-8494-d8486add6aa4",
          "desc": {
            "msg": "AssistantMessage",
            "tool_calls": [
              {
                "id": "tc0",
                "function": {
                  "name": "execute_command",
                  "arguments": "{\"command\":\"date\"}",
                },
                "type": "function",
              },
            ],
            "content": "Hi",
          },
        },
        {
          "id": "f378dd8d-6f56-4e4d-8d63-4ff59e92f44c",
          "desc": {
            "msg": "PostToolCall",
            "tool_call": {
              "id": "tc0",
              "function": {
                "name": "execute_command",
                "arguments": "{\"command\":\"date\"}",
              },
              "type": "function",
            },
            "name": "execute_command",
            "result": "2024-01-01T12:00:00Z",
            "text": "2024-01-01T12:00:00Z",
          },
        },
        {
          "id": "42858c8d-3684-43ab-837d-ef6894a9b8dc",
          "desc": {
            "msg": "AssistantMessage",
            "tool_calls": [],
            "content": "Current time is 2024-01-01T12:00:00Z",
          },
        },
      ],
    )
    let json : Json = {
      "name": "Test Conversation",
      "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
      "system_prompt": "This is a system prompt.",
      "events": events,
      "created_at": "0",
      "updated_at": "5",
      "cwd": "/home/user/project",
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
        #|  What time is it now
        #|1. [assistant]
        #|  Hi
        #|2. [tool]
        #|  2024-01-01T12:00:00Z
        #|3. [assistant]
        #|  Current time is 2024-01-01T12:00:00Z
        #|Created: 1970-01-01T00:00:00Z
        #|Updated: 1970-01-01T00:00:00Z
      ),
    )
  })
}
