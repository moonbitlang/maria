///|
fn redact_events(events : Array[@event.Event]) -> Array[Json] {
  events.map(event => event
    .to_json()
    .transform(
      @json.Replacer::exclude(["level", "pid", "hostname", "time", "tag"]),
    ))
}

///|
async test "Event::ToJson/PreConversation" (t : @test.Test) {
  @mock.run(t, _ => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new()
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(PreConversation)
    })
    @json.inspect(redact_events(events), content=[{ "msg": "PreConversation" }])
  })
}

///|
async test "Event::ToJson/PostConversation" (t : @test.Test) {
  @mock.run(t, _ => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new()
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(PostConversation)
    })
    @json.inspect(redact_events(events), content=[{ "msg": "PostConversation" }])
  })
}

///|
async test "Event::ToJson/TokenCounted" (t : @test.Test) {
  @mock.run(t, _ => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new()
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(TokenCounted(42))
    })
    @json.inspect(redact_events(events), content=[
      { "msg": "TokenCounted", "token_count": 42 },
    ])
  })
}

///|
async test "Event::ToJson/ContextPruned" (t : @test.Test) {
  @mock.run(t, _ => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new()
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(ContextPruned(origin_token_count=100, pruned_token_count=20))
    })
    @json.inspect(redact_events(events), content=[
      {
        "msg": "ContextPruned",
        "origin_token_count": 100,
        "pruned_token_count": 20,
      },
    ])
  })
}

///|
async test "Event::ToJson/PreToolCall" (t : @test.Test) {
  @mock.run(t, _ => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new()
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
    @json.inspect(redact_events(events), content=[
      {
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
    ])
  })
}

///|
async test "Event::ToJson/PostToolCall success" (t : @test.Test) {
  @mock.run(t, _ => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new()
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
    @json.inspect(redact_events(events), content=[
      {
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
    ])
  })
}

///|
async test "Event::ToJson/PostToolCall error" (t : @test.Test) {
  @mock.run(t, _ => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new()
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
          result=Err(Failure("Tool call error")),
          rendered="Tool call error output",
        ),
      )
    })
    @json.inspect(redact_events(events), content=[
      {
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
    ])
  })
}

///|
async test "Event::ToJson/MessageAdded" (t : @test.Test) {
  @mock.run(t, _ => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new()
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(
        MessageAdded(@ai.user_message(content="Hello, this is a user message.")),
      )
    })
    @json.inspect(redact_events(events), content=[
      {
        "msg": "MessageAdded",
        "message": {
          "role": "user",
          "content": "Hello, this is a user message.",
        },
      },
    ])
  })
}

///|
async test "Event::ToJson/ToolAdded" (t : @test.Test) {
  @mock.run(t, _ => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new()
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
    @json.inspect(redact_events(events), content=[
      {
        "msg": "ToolAdded",
        "tool": {
          "name": "sample_tool",
          "description": "A sample tool for demonstration.",
          "schema": "{\"type\": \"object\", \"properties\": {\"param\": {\"type\": \"string\"}}}",
        },
      },
    ])
  })
}

///|
async test "Event::ToJson/RequestCompleted" (t : @test.Test) {
  @mock.run(t, _ => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new()
      emitter.add_listener(event => events.push(event))
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      let usage : @ai.Usage = @ai.usage(
        input_tokens=150,
        output_tokens=50,
        total_tokens=200,
      )
      let message : @ai.Message = @ai.assistant_message(
        content="This is the final message from the model.",
        tool_calls=[],
      )
      emitter.emit(RequestCompleted(usage=Some(usage), message~))
    })
    @json.inspect(redact_events(events), content=[
      {
        "msg": "RequestCompleted",
        "usage": [
          { "completion_tokens": 50, "prompt_tokens": 150, "total_tokens": 200 },
        ],
        "message": {
          "role": "assistant",
          "tool_calls": [],
          "content": "This is the final message from the model.",
        },
      },
    ])
  })
}

///|
async test "Event::ModelLoaded" (t : @test.Test) {
  @mock.run(t, _ => {
    let events = []
    @async.with_task_group(group => {
      let emitter = @event.EventTarget::new()
      group.spawn_bg(() => emitter.start(), no_wait=true)
      @async.pause()
      emitter.add_listener(event => events.push(event))
      emitter.emit(
        ModelLoaded(
          name="test_model",
          model=@model.Model::new(
            api_key="test_api_key",
            base_url="https://api.example.com",
            name="test_model",
            safe_zone_tokens=100000,
          ),
        ),
      )
    })
    @json.inspect(redact_events(events), content=[
      {
        "msg": "ModelLoaded",
        "name": "test_model",
        "model": {
          "name": "test_model",
          "model_name": "test_model",
          "model_type": "saas/openai",
          "api_key": "****",
          "base_url": "https://api.example.com",
          "safe_zone_tokens": 100000,
          "supports_anthropic_prompt_caching": false,
        },
      },
    ])
  })
}
