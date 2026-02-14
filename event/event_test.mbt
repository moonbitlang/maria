///|
async test "EventTarget::flush" (t : @test.Test) {
  @mock.run(t, mock => {
    let event_target = @event.EventTarget::new(uuid=mock.uuid, clock=mock.clock)
    let events : Array[@event.Event] = []
    event_target.add_listener(event => events.push(event))
    @async.with_task_group(group => {
      let task = group.spawn(() => event_target.start(), allow_failure=true)
      task.cancel()
      let task = group.spawn(() => event_target.start(), allow_failure=true)
      event_target.emit(TokenCounted(10))
      event_target.flush()
      task.cancel()
    })
    json_inspect(events, content=[
      {
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "created": 0,
        "desc": { "msg": "TokenCounted", "token_count": 10 },
      },
    ])
  })
}

///|
async test "Event::ToJson/PreConversation" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new(uuid=mock.uuid, clock=mock.clock)
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(PreConversation)
    })
    json_inspect(events, content=[
      {
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "created": 0,
        "desc": { "msg": "PreConversation" },
      },
    ])
  })
}

///|
async test "Event::ToJson/PostConversation" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new(uuid=mock.uuid, clock=mock.clock)
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(PostConversation)
    })
    json_inspect(events, content=[
      {
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "created": 0,
        "desc": { "msg": "PostConversation" },
      },
    ])
  })
}

///|
async test "Event::ToJson/TokenCounted" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new(uuid=mock.uuid, clock=mock.clock)
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(TokenCounted(42))
    })
    json_inspect(events, content=[
      {
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "created": 0,
        "desc": { "msg": "TokenCounted", "token_count": 42 },
      },
    ])
  })
}

///|
async test "Event::ToJson/ContextPruned" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new(uuid=mock.uuid, clock=mock.clock)
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(ContextPruned(origin_token_count=100, pruned_token_count=20))
    })
    json_inspect(events, content=[
      {
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "created": 0,
        "desc": {
          "msg": "ContextPruned",
          "origin_token_count": 100,
          "pruned_token_count": 20,
        },
      },
    ])
  })
}

///|
async test "Event::ToJson/PreToolCall" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new(uuid=mock.uuid, clock=mock.clock)
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(
        PreToolCall(
          @ai.tool_call(
            id="tool_call_1",
            name="example_tool",
            arguments="{\"param1\": \"value1\", \"param2\": 123}",
          ),
        ),
      )
    })
    json_inspect(events, content=[
      {
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "created": 0,
        "desc": {
          "msg": "PreToolCall",
          "tool_call": {
            "id": "tool_call_1",
            "function": {
              "name": "example_tool",
              "arguments": "{\"param1\": \"value1\", \"param2\": 123}",
            },
            "type": "function",
          },
          "name": "example_tool",
          "args": { "param1": "value1", "param2": 123 },
        },
      },
    ])
  })
}

///|
async test "Event::ToJson/PostToolCall success" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new(uuid=mock.uuid, clock=mock.clock)
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(
        PostToolCall(
          @ai.tool_call(
            id="tool_call_1",
            name="example_tool",
            arguments="{\"param1\": \"value1\", \"param2\": 123}",
          ),
          result=Ok("Tool call result"),
          rendered="Tool call rendered output",
        ),
      )
    })
    json_inspect(events, content=[
      {
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "created": 0,
        "desc": {
          "msg": "PostToolCall",
          "tool_call": {
            "id": "tool_call_1",
            "function": {
              "name": "example_tool",
              "arguments": "{\"param1\": \"value1\", \"param2\": 123}",
            },
            "type": "function",
          },
          "name": "example_tool",
          "result": "Tool call result",
          "text": "Tool call rendered output",
        },
      },
    ])
  })
}

///|
async test "Event::ToJson/PostToolCall error" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new(uuid=mock.uuid, clock=mock.clock)
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(
        PostToolCall(
          @ai.tool_call(
            id="tool_call_2",
            name="failing_tool",
            arguments="{\"paramA\": \"valueA\"}",
          ),
          result=Err(Failure::Failure("Tool call error").to_json()),
          rendered="Tool call error output",
        ),
      )
    })
    json_inspect(events, content=[
      {
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "created": 0,
        "desc": {
          "msg": "PostToolCall",
          "tool_call": {
            "id": "tool_call_2",
            "function": {
              "name": "failing_tool",
              "arguments": "{\"paramA\": \"valueA\"}",
            },
            "type": "function",
          },
          "name": "failing_tool",
          "error": ["Failure", "Tool call error"],
          "text": "Tool call error output",
        },
      },
    ])
  })
}

///|
async test "Event::ToJson/SystemPromptSet" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new(uuid=mock.uuid, clock=mock.clock)
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(SystemPromptSet(Some("Hello, this is a system prompt.")))
      emitter.emit(SystemPromptSet(None))
    })
    json_inspect(events, content=[
      {
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "created": 0,
        "desc": {
          "msg": "SystemPromptSet",
          "prompt": "Hello, this is a system prompt.",
        },
      },
      {
        "id": "1ea1417c-a31f-4b1b-8494-d8486add6aa4",
        "created": 1,
        "desc": { "msg": "SystemPromptSet" },
      },
    ])
  })
}

///|
async test "Event::ToJson/ToolAdded" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new(uuid=mock.uuid, clock=mock.clock)
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      let tool = @tool.new(
        description="A sample tool for demonstration.",
        name="sample_tool",
        schema="{\"type\": \"object\", \"properties\": {\"param\": {\"type\": \"string\"}}}",
        _ => @tool.ToolResult::ok("Sample output"),
      )
      emitter.emit(ToolAdded(tool.desc))
    })
    json_inspect(events, content=[
      {
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "created": 0,
        "desc": {
          "msg": "ToolAdded",
          "tool": {
            "name": "sample_tool",
            "description": "A sample tool for demonstration.",
            "schema": "{\"type\": \"object\", \"properties\": {\"param\": {\"type\": \"string\"}}}",
          },
        },
      },
    ])
  })
}

///|
async test "Event::ToJson/AssistantMessage" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new(uuid=mock.uuid, clock=mock.clock)
      emitter.add_listener(event => events.push(event))
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      let usage : @ai.Usage = @ai.usage(
        input_tokens=150,
        output_tokens=50,
        total_tokens=200,
      )
      emitter.emit(
        AssistantMessage(
          usage=Some(usage),
          tool_calls=[],
          "This is the final message from the model.",
        ),
      )
    })
    json_inspect(events, content=[
      {
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "created": 0,
        "desc": {
          "msg": "AssistantMessage",
          "tool_calls": [],
          "content": "This is the final message from the model.",
          "usage": {
            "completion_tokens": 50,
            "prompt_tokens": 150,
            "total_tokens": 200,
          },
        },
      },
    ])
  })
}

///|
async test "Event::ModelLoaded" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new(uuid=mock.uuid, clock=mock.clock)
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(ModelLoaded(name="test_model"))
    })
    json_inspect(events, content=[
      {
        "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
        "created": 0,
        "desc": { "msg": "ModelLoaded", "name": "test_model" },
      },
    ])
  })
}

///|
test "Event::Roundtrip/PreConversation" {
  let event : @event.EventDesc = PreConversation
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    PreConversation => ()
    _ => fail("Expected PreConversation")
  }
}

///|
test "Event::Roundtrip/PostConversation" {
  let event : @event.EventDesc = PostConversation
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    PostConversation => ()
    _ => fail("Expected PostConversation")
  }
}

///|
test "Event::Roundtrip/TokenCounted" {
  let event : @event.EventDesc = TokenCounted(42)
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    TokenCounted(count) => inspect(count, content="42")
    _ => fail("Expected TokenCounted")
  }
}

///|
test "Event::Roundtrip/ContextPruned" {
  let event : @event.EventDesc = ContextPruned(
    origin_token_count=100,
    pruned_token_count=20,
  )
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    ContextPruned(origin_token_count~, pruned_token_count~) => {
      inspect(origin_token_count, content="100")
      inspect(pruned_token_count, content="20")
    }
    _ => fail("Expected ContextPruned")
  }
}

///|
test "Event::Roundtrip/PreToolCall" {
  let tool_call = @ai.tool_call(
    id="tool_call_1",
    name="example_tool",
    arguments="{\"param1\": \"value1\", \"param2\": 123}",
  )
  let event : @event.EventDesc = PreToolCall(tool_call)
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    PreToolCall(tc) => {
      inspect(tc.id, content="tool_call_1")
      inspect(tc.name, content="example_tool")
      inspect(
        tc.arguments,
        content=(
          #|Some("{\"param1\": \"value1\", \"param2\": 123}")
        ),
      )
    }
    _ => fail("Expected PreToolCall")
  }
}

///|
test "Event::Roundtrip/PostToolCall/Ok" {
  let tool_call = @ai.tool_call(
    id="tool_call_1",
    name="example_tool",
    arguments="{\"param1\": \"value1\"}",
  )
  let event : @event.EventDesc = PostToolCall(
    tool_call,
    result=Ok({ "output": "success" }),
    rendered="Tool output: success",
  )
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    PostToolCall(tc, result~, rendered~) => {
      inspect(tc.id, content="tool_call_1")
      inspect(tc.name, content="example_tool")
      inspect(
        result,
        content=(
          #|Ok(Object({"output": String("success")}))
        ),
      )
      inspect(rendered, content="Tool output: success")
    }
    _ => fail("Expected PostToolCall")
  }
}

///|
test "Event::Roundtrip/PostToolCall/Err" {
  let tool_call = @ai.tool_call(
    id="tool_call_2",
    name="failing_tool",
    arguments="{}",
  )
  let event : @event.EventDesc = PostToolCall(
    tool_call,
    result=Err({ "error": "Something went wrong" }),
    rendered="Error occurred",
  )
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    PostToolCall(tc, result~, rendered~) => {
      inspect(tc.id, content="tool_call_2")
      inspect(
        result,
        content=(
          #|Err(Object({"error": String("Something went wrong")}))
        ),
      )
      inspect(rendered, content="Error occurred")
    }
    _ => fail("Expected PostToolCall")
  }
}

///|
test "Event::Roundtrip/SystemPromptSet/Some" {
  let event : @event.EventDesc = SystemPromptSet(
    Some("You are a helpful assistant."),
  )
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    SystemPromptSet(msg) =>
      inspect(
        msg,
        content=(
          #|Some("You are a helpful assistant.")
        ),
      )
    _ => fail("Expected SystemPromptSet")
  }
}

///|
test "Event::Roundtrip/SystemPromptSet/None" {
  let event : @event.EventDesc = SystemPromptSet(None)
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    SystemPromptSet(msg) => inspect(msg, content="None")
    _ => fail("Expected SystemPromptSet")
  }
}

///|
test "Event::Roundtrip/MessageQueued" {
  let id = @uuid.nil
  let event : @event.EventDesc = MessageQueued(id~)
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    MessageQueued(id=roundtrip_id) =>
      inspect(roundtrip_id == id, content="true")
    _ => fail("Expected MessageQueued")
  }
}

///|
test "Event::Roundtrip/MessageUnqueued" {
  let id = @uuid.nil
  let event : @event.EventDesc = MessageUnqueued(id~)
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    MessageUnqueued(id=roundtrip_id) =>
      inspect(roundtrip_id == id, content="true")
    _ => fail("Expected MessageUnqueued")
  }
}

///|
test "Event::Roundtrip/ToolAdded" {
  let tool_desc = @tool.tool_desc(
    name="sample_tool",
    description="A sample tool",
    schema=@tool.JsonSchema::from_json({ "type": "object" }),
  )
  let event : @event.EventDesc = ToolAdded(tool_desc)
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    ToolAdded(desc) => {
      inspect(desc.name, content="sample_tool")
      inspect(desc.description, content="A sample tool")
      inspect(
        desc.schema.to_json(),
        content=(
          #|Object({"type": String("object")})
        ),
      )
    }
    _ => fail("Expected ToolAdded")
  }
}

///|
test "Event::Roundtrip/AssistantMessage/WithUsage" {
  let usage = @ai.usage(input_tokens=100, output_tokens=50, total_tokens=150)
  let event : @event.EventDesc = AssistantMessage(
    usage=Some(usage),
    tool_calls=[],
    "Response from model",
  )
  let json = event.to_json()
  json_inspect(json, content={
    "msg": "AssistantMessage",
    "tool_calls": [],
    "content": "Response from model",
    "usage": {
      "completion_tokens": 50,
      "prompt_tokens": 100,
      "total_tokens": 150,
    },
  })
  let roundtripped : @event.EventDesc = @json.from_json(json)
  assert_eq(roundtripped, event)
}

///|
test "Event::Roundtrip/AssistantMessage/NoUsage" {
  let tool_calls = []
  tool_calls.push(@ai.tool_call(id="tc1", name="tool1", arguments="{}"))
  let event : @event.EventDesc = AssistantMessage(
    usage=None,
    tool_calls~,
    "Response",
  )
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  assert_eq(roundtripped, event)
}

///|
test "Event::Roundtrip/Cancelled" {
  let event : @event.EventDesc = Cancelled
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    Cancelled => ()
    _ => fail("Expected Cancelled")
  }
}

///|
test "Event::Roundtrip/ModelLoaded" {
  let event : @event.EventDesc = ModelLoaded(name="my_model")
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    ModelLoaded(name~) => inspect(name, content="my_model")
    _ => fail("Expected ModelLoaded")
  }
}

///|
test "ExternalEvent::Roundtrip/Cancel" {
  let event : @event.EventDesc = Cancelled
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    Cancelled => ()
    _ => fail("Expected Cancel")
  }
}

///|
test "ExternalEvent::Roundtrip/UserMessage" {
  let event : @event.EventDesc = UserMessage("Stop the current task")
  let json = event.to_json()
  let roundtripped : @event.EventDesc = @json.from_json(json)
  match roundtripped {
    UserMessage(msg) => inspect(msg, content="Stop the current task")
    _ => fail("Expected UserMessage")
  }
}

///|
test "Event::Roundtrip" {
  let uuid = @uuid.generator(@rand.chacha8())
  let events : Array[EventDesc] = [
    PreConversation,
    PostConversation,
    TokenCounted(42),
    ContextPruned(origin_token_count=100, pruned_token_count=20),
    PreToolCall(
      @ai.tool_call(
        id="tool_call_1",
        name="example_tool",
        arguments="{\"param1\": \"value1\", \"param2\": 123}",
      ),
    ),
    PostToolCall(
      @ai.tool_call(
        id="tool_call_1",
        name="example_tool",
        arguments="{\"param1\": \"value1\", \"param2\": 123}",
      ),
      result=Ok("Tool call result"),
      rendered="Tool call rendered output",
    ),
    SystemPromptSet(Some("Hello, this is a system prompt.")),
    SystemPromptSet(None),
    ToolAdded(
      @tool.tool_desc(
        name="sample_tool",
        description="A sample tool for demonstration.",
        schema="{\"type\": \"object\", \"properties\": {\"param\": {\"type\": \"string\"}}}",
      ),
    ),
    AssistantMessage(
      usage=Some(
        @ai.usage(input_tokens=150, output_tokens=50, total_tokens=200),
      ),
      tool_calls=[],
      "This is the final message from the model.",
    ),
    ModelLoaded(name="test_model"),
    Cancelled,
    UserMessage("Stop the current task"),
    Failed(Failure::Failure("An error occurred").to_json()),
  ]
  for event in events {
    let event = @event.Event::new(id=uuid.v4(), event)
    let roundtripped : @event.Event = @json.from_json(event.to_json())
    assert_eq(roundtripped, event)
  }
}
