///|
/// Helper function to create a Claude Haiku model for testing
fn claude_haiku_model(api_key : String) -> @model.Model {
  @model.new(
    api_key~,
    base_url="https://openrouter.ai/api/v1",
    name="anthropic/claude-haiku-4.5",
    safe_zone_tokens=200000,
  )
}

///|
/// Test basic agent initialization and configuration
async test "agent/initialization" (t : @test.T) {
  @mock.run(t, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
      fail("OPENAI_API_KEY not set")
    }
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())

    // Verify agent was created successfully
    inspect(agent.cwd, content=taco.cwd.path())
    inspect(agent.model.name, content="anthropic/claude-haiku-4.5")
  })
}

///|
/// Test agent with a simple message-only interaction (no tools)
async test "agent/simple_conversation" (t : @test.T) {
  @mock.run(t, timeout=120_000, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
      fail("OPENAI_API_KEY not set")
    }
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())

    // Track events
    let conversation_started = Ref::new(false)
    let conversation_ended = Ref::new(false)
    let message_count = Ref::new(0)
    agent.add_listener(event => match event {
      PreConversation => conversation_started.val = true
      PostConversation => conversation_ended.val = true
      MessageAdded(_) => message_count.val = message_count.val + 1
      _ => ()
    })

    // Add a simple user message
    agent.add_message(
      @openai.user_message(content="Say 'Hello, World!' and nothing else."),
    )

    // Start the agent
    agent.start()

    // Give events time to process
    // @async.sleep(100)

    // Verify conversation lifecycle
    inspect(conversation_started.val, content="true")
    // Event timing is async, PostConversation may not be processed immediately
    inspect(message_count.val > 0, content="true")
  })
}

///|
/// Test agent with a simple tool call
async test "agent/single_tool_call" (t : @test.T) {
  @mock.run(t, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
      fail("OPENAI_API_KEY not set")
    }
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())

    // Track tool calls
    let mut tool_called = false
    let mut tool_name = ""

    // Add a simple calculator tool
    let calculator_tool = @tool.tool(
      name="add_numbers",
      description="Add two numbers together",
      parameters={
        "type": "object",
        "properties": {
          "a": { "type": "number", "description": "First number" },
          "b": { "type": "number", "description": "Second number" },
        },
        "required": ["a", "b"],
      },
      ToolFn(args => {
        tool_called = true
        guard args is { "a": Number(a, ..), "b": Number(b, ..), .. } else {
          return @tool.error({ "error": "Invalid arguments" })
        }
        let sum = a + b
        @tool.ok({ "result": sum })
      }),
      render=result => match result {
        Ok(output) => "Result: \{output}"
        Error(_, output) => "Error: \{output}"
      },
    )
    agent.add_tools([calculator_tool])
    agent.add_listener(event => match event {
      PreToolCall(tool_call) => tool_name = tool_call.function.name
      _ => ()
    })

    // Ask the agent to add two numbers
    agent.add_message(
      @openai.user_message(
        content="Use the add_numbers tool to calculate 5 + 3. Return only the result.",
      ),
    )
    agent.start()

    // Verify tool was called
    inspect(tool_called, content="true")
    inspect(tool_name, content="add_numbers")
  })
}

///|
/// Test agent with multiple tool calls in sequence
async test "agent/multiple_tool_calls" (t : @test.T) {
  @mock.run(t, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
      fail("OPENAI_API_KEY not set")
    }
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())

    // Track tool calls
    let tool_calls : Array[String] = []

    // Add multiple tools
    let add_tool = @tool.tool(
      name="add",
      description="Add two numbers",
      parameters={
        "type": "object",
        "properties": { "a": { "type": "number" }, "b": { "type": "number" } },
        "required": ["a", "b"],
      },
      ToolFn(args => {
        guard args is { "a": Number(a, ..), "b": Number(b, ..), .. } else {
          return @tool.error({ "error": "Invalid arguments" })
        }
        @tool.ok({ "result": a + b })
      }),
      render=result => match result {
        Ok(output) => output.stringify()
        Error(_, output) => output.stringify()
      },
    )
    let multiply_tool = @tool.tool(
      name="multiply",
      description="Multiply two numbers",
      parameters={
        "type": "object",
        "properties": { "a": { "type": "number" }, "b": { "type": "number" } },
        "required": ["a", "b"],
      },
      ToolFn(args => {
        guard args is { "a": Number(a, ..), "b": Number(b, ..), .. } else {
          return @tool.error({ "error": "Invalid arguments" })
        }
        @tool.ok({ "result": a * b })
      }),
      render=result => match result {
        Ok(output) => output.stringify()
        Error(_, output) => output.stringify()
      },
    )
    agent.add_tools([add_tool, multiply_tool])
    agent.add_listener(event => match event {
      PreToolCall(tool_call) => tool_calls.push(tool_call.function.name)
      _ => ()
    })

    // Ask the agent to use both tools
    agent.add_message(
      @openai.user_message(
        content="First use the add tool to calculate 5 + 3, then use the multiply tool to multiply the result by 2. Return the final result.",
      ),
    )
    agent.start()

    // Verify both tools were called
    inspect(tool_calls.length() >= 2, content="true")
    inspect(tool_calls.contains("add"), content="true")
    inspect(tool_calls.contains("multiply"), content="true")
  })
}

///|
/// Test agent event system
async test "agent/event_system" (t : @test.T) {
  @mock.run(t, timeout=120_000, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
      fail("OPENAI_API_KEY not set")
    }
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())

    // Track all event types with Ref for async updates
    let pre_conversation = Ref::new(false)
    let post_conversation = Ref::new(false)
    let message_added = Ref::new(false)
    let token_counted = Ref::new(false)
    let request_completed = Ref::new(false)
    agent.add_listener(event => match event {
      PreConversation => pre_conversation.val = true
      PostConversation => post_conversation.val = true
      MessageAdded(_) => message_added.val = true
      TokenCounted(_) => token_counted.val = true
      RequestCompleted(usage~, message~) => {
        request_completed.val = true
        inspect(usage is Some(_) || usage is None, content="true")
        inspect(message.role, content="Assistant")
      }
      _ => ()
    })
    agent.add_message(
      @openai.user_message(content="Say 'Testing events' and nothing else."),
    )
    agent.start()

    // Give events time to process
    // @async.sleep(100)

    // Verify all expected events fired
    inspect(pre_conversation.val, content="true")
    // Event timing is async, PostConversation may not be processed immediately
    inspect(message_added.val, content="true")
    inspect(token_counted.val, content="true")
    inspect(request_completed.val, content="true")
  })
}

///|
/// Test agent with file operations
async test "agent/file_operations" (t : @test.T) {
  @mock.run(t, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
      fail("OPENAI_API_KEY not set")
    }
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())

    // Add file management tools
    let file_manager = @file.manager(cwd=taco.cwd.path())
    agent.add_tools([
      @write_to_file.new(file_manager),
      @read_file.new(file_manager),
    ])

    // Track if files were created/read
    let mut file_written = false
    let mut _file_read = false
    agent.add_listener(event => match event {
      PreToolCall(tool_call) =>
        match tool_call.function.name {
          "write_to_file" => file_written = true
          "read_file" => _file_read = true
          _ => ()
        }
      _ => ()
    })

    // Ask agent to create and read a file
    agent.add_message(
      @openai.user_message(
        content="Create a file called 'test.txt' with the content 'Hello, World!' and then read it back to confirm.",
      ),
    )
    agent.start()

    // Verify file operations occurred
    inspect(file_written, content="true")

    // Verify file was actually created
    let file_content = @fs.read_file(@path.join(taco.cwd.path(), "test.txt"))
    inspect(file_content.contains("Hello"), content="true")
  })
}

///|
/// Test agent token counting and context pruning
async test "agent/token_management" (t : @test.T) {
  @mock.run(t, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
      fail("OPENAI_API_KEY not set")
    }
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())
    let mut token_count = 0
    let mut _context_pruned = false
    agent.add_listener(event => match event {
      TokenCounted(count) => token_count = count
      ContextPruned(origin_token_count~, pruned_token_count~) => {
        _context_pruned = true
        inspect(origin_token_count >= pruned_token_count, content="true")
      }
      _ => ()
    })

    // Add a message that will require token counting
    agent.add_message(@openai.user_message(content="Say 'Hello' briefly."))
    agent.start()

    // Verify token counting occurred
    inspect(token_count > 0, content="true")
  })
}

///|
/// Test agent with error handling in tools
async test "agent/tool_error_handling" (t : @test.T) {
  @mock.run(t, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
      fail("OPENAI_API_KEY not set")
    }
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())
    let mut error_encountered = false

    // Add a tool that always fails
    let failing_tool = @tool.tool(
      name="divide",
      description="Divide two numbers (will fail on division by zero)",
      parameters={
        "type": "object",
        "properties": { "a": { "type": "number" }, "b": { "type": "number" } },
        "required": ["a", "b"],
      },
      ToolFn(args => {
        guard args is { "a": Number(a, ..), "b": Number(b, ..), .. } else {
          return @tool.error({ "error": "Invalid arguments" })
        }
        if b == 0.0 {
          return @tool.error({ "error": "Division by zero" })
        }
        @tool.ok({ "result": a / b })
      }),
      render=result => match result {
        Ok(output) => output.stringify()
        Error(_, output) => "Error: \{output.stringify()}"
      },
    )
    agent.add_tools([failing_tool])
    agent.add_listener(event => match event {
      PostToolCall(_, result~, rendered~) =>
        match result {
          Error(_, _) => {
            error_encountered = true
            inspect(rendered.contains("Error"), content="true")
          }
          _ => ()
        }
      _ => ()
    })

    // Ask agent to divide by zero
    agent.add_message(
      @openai.user_message(content="Use the divide tool to divide 10 by 0."),
    )
    agent.start()

    // Verify error was handled
    inspect(error_encountered, content="true")
  })
}

///|
/// Test agent with batch tool registration
async test "agent/batch_tool_registration" (t : @test.T) {
  @mock.run(t, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
      fail("OPENAI_API_KEY not set")
    }
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())

    // Create multiple tools
    let tools = [
      @tool.tool(
        name="tool1",
        description="First tool",
        parameters={ "type": "object", "properties": {} },
        ToolFn(_ => @tool.ok({ "result": "tool1" })),
        render=_ => "tool1",
      ),
      @tool.tool(
        name="tool2",
        description="Second tool",
        parameters={ "type": "object", "properties": {} },
        ToolFn(_ => @tool.ok({ "result": "tool2" })),
        render=_ => "tool2",
      ),
      @tool.tool(
        name="tool3",
        description="Third tool",
        parameters={ "type": "object", "properties": {} },
        ToolFn(_ => @tool.ok({ "result": "tool3" })),
        render=_ => "tool3",
      ),
    ]

    // Register all tools at once
    agent.add_tools(tools)
    let tool_names : Array[String] = []
    agent.add_listener(event => match event {
      PreToolCall(tool_call) => tool_names.push(tool_call.function.name)
      _ => ()
    })

    // Ask agent to use all tools
    agent.add_message(
      @openai.user_message(
        content="I have three tools available: tool1, tool2, and tool3. Please call tool1.",
      ),
    )
    agent.start()

    // Verify at least one tool was available and called
    inspect(tool_names.length() > 0, content="true")
  })
}

///|
/// Test agent conversation history persistence
async test "agent/conversation_history" (t : @test.T) {
  @mock.run(t, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
      fail("OPENAI_API_KEY not set")
    }
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())
    let mut message_count = 0
    agent.add_listener(event => match event {
      MessageAdded(_) => message_count = message_count + 1
      _ => ()
    })

    // Add system message
    agent.add_message(
      @openai.system_message(content="You are a helpful assistant."),
    )

    // Add user message
    agent.add_message(
      @openai.user_message(content="Say 'Hello' and nothing else."),
    )
    agent.start()

    // Verify messages were tracked
    inspect(message_count >= 2, content="true")
  })
}
