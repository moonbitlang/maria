///|
fn redact_log_entries(json : Array[Json]) -> Array[Json] {
  json.map(json => json.transform(
    @json.Replacer::exclude(["level", "pid", "hostname", "time", "tag"]),
  ))
}

///|
#skip
async test "Event::ToJson/PreConversation" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    let logger = @pino.logger(
      "event_test",
      @pino.Transport::callback(event => events.push(event)),
    )
    let agent = new(mock.model(), cwd=mock.cwd.path(), logger~)
    agent.emit(PreConversation)
    @json.inspect(redact_log_entries(events), content=[
      { "msg": "PreConversation" },
    ])
  })
}

///|
#skip
async test "Event::ToJson/PostConversation" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    let logger = @pino.logger(
      "event_test",
      @pino.Transport::callback(event => events.push(event)),
    )
    let agent = new(mock.model(), cwd=mock.cwd.path(), logger~)
    agent.emit(PostConversation)
    @json.inspect(redact_log_entries(events), content=[
      { "msg": "PostConversation" },
    ])
  })
}

///|
#skip
async test "Event::ToJson/TokenCounted" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    let logger = @pino.logger(
      "event_test",
      @pino.Transport::callback(event => events.push(event)),
    )
    let agent = new(mock.model(), cwd=mock.cwd.path(), logger~)
    agent.emit(TokenCounted(42))
    @json.inspect(redact_log_entries(events), content=[
      { "msg": "TokenCounted", "token_count": 42 },
    ])
  })
}

///|
#skip
async test "Event::ToJson/ContextPruned" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    let logger = @pino.logger(
      "event_test",
      @pino.Transport::callback(event => events.push(event)),
    )
    let agent = new(mock.model(), cwd=mock.cwd.path(), logger~)
    agent.emit(ContextPruned(origin_token_count=100, pruned_token_count=20))
    @json.inspect(redact_log_entries(events), content=[
      {
        "msg": "ContextPruned",
        "origin_token_count": 100,
        "pruned_token_count": 20,
      },
    ])
  })
}

///|
#skip
async test "Event::ToJson/PreToolCall" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    let logger = @pino.logger(
      "event_test",
      @pino.Transport::callback(event => events.push(event)),
    )
    let agent = new(mock.model(), cwd=mock.cwd.path(), logger~)
    agent.emit(
      PreToolCall(
        @openai.tool_call(
          id="tool_call_1",
          name="example_tool",
          arguments="{\"param1\": \"value1\", \"param2\": 123}",
        ),
      ),
    )
    @json.inspect(redact_log_entries(events), content=[
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
#skip
async test "Event::ToJson/PostToolCall success" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    let logger = @pino.logger(
      "event_test",
      @pino.Transport::callback(event => events.push(event)),
    )
    let agent = new(mock.model(), cwd=mock.cwd.path(), logger~)
    agent.emit(
      PostToolCall(
        @openai.tool_call(
          id="tool_call_1",
          name="example_tool",
          arguments="{\"param1\": \"value1\", \"param2\": 123}",
        ),
        result=Ok("Tool call result"),
        rendered="Tool call rendered output",
      ),
    )
    @json.inspect(redact_log_entries(events), content=[
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
#skip
async test "Event::ToJson/PostToolCall error" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    let logger = @pino.logger(
      "event_test",
      @pino.Transport::callback(event => events.push(event)),
    )
    let agent = new(mock.model(), cwd=mock.cwd.path(), logger~)
    agent.emit(
      PostToolCall(
        @openai.tool_call(
          id="tool_call_2",
          name="failing_tool",
          arguments="{\"paramA\": \"valueA\"}",
        ),
        result=Err(Failure("Tool call error")),
        rendered="Tool call error output",
      ),
    )
    @json.inspect(redact_log_entries(events), content=[
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
#skip
async test "Event::ToJson/MessageAdded" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    let logger = @pino.logger(
      "event_test",
      @pino.Transport::callback(event => events.push(event)),
    )
    let agent = new(mock.model(), cwd=mock.cwd.path(), logger~)
    agent.emit(
      MessageAdded(
        @openai.user_message(content="Hello, this is a user message."),
      ),
    )
    @json.inspect(redact_log_entries(events), content=[
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
#skip
async test "Event::ToJson/ToolAdded" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    let logger = @pino.logger(
      "event_test",
      @pino.Transport::callback(event => events.push(event)),
    )
    let agent = new(mock.model(), cwd=mock.cwd.path(), logger~)
    let tool = @tool.new(
      description="A sample tool for demonstration.",
      name="sample_tool",
      schema="{\"type\": \"object\", \"properties\": {\"param\": {\"type\": \"string\"}}}",
      _ => @tool.ToolResult::ok("Sample output"),
    )
    agent.emit(ToolAdded(tool.desc))
    @json.inspect(redact_log_entries(events), content=[
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
#skip
async test "Event::ToJson/RequestCompleted" (t : @test.Test) {
  @mock.run(t, mock => {
    let events = []
    let logger = @pino.logger(
      "event_test",
      @pino.Transport::callback(event => events.push(event)),
    )
    let agent = new(mock.model(), cwd=mock.cwd.path(), logger~)
    let usage : Json = {
      "completion_tokens": 50,
      "prompt_tokens": 150,
      "total_tokens": 200,
    }
    let usage : @openai.CompletionUsage = @json.from_json(usage)
    let message : Json = {
      "content": "This is the final message from the model.",
      "role": "assistant",
      "tool_calls": [],
    }
    let message : @openai.ChatCompletionMessage = @json.from_json(message)
    agent.emit(RequestCompleted(usage=Some(usage), message~))
    @json.inspect(redact_log_entries(events), content=[
      {
        "msg": "RequestCompleted",
        "usage": [
          { "completion_tokens": 50, "prompt_tokens": 150, "total_tokens": 200 },
        ],
        "message": {
          "content": "This is the final message from the model.",
          "role": "assistant",
          "tool_calls": [],
        },
      },
    ])
  })
}
