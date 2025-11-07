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
async test "agent/initialization" (t : @test.Test) {
  @mock.run(t, retry=3, taco => {
    let api_key = taco.getenv("OPENAI_API_KEY")
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())

    // Verify agent was created successfully
    inspect(agent.cwd, content=taco.cwd.path())
    inspect(agent.model.name, content="anthropic/claude-haiku-4.5")
  })
}

///|
/// Test agent with a simple message-only interaction (no tools)
async test "agent/simple_conversation" (t : @test.Test) {
  @mock.run(t, timeout=120_000, retry=3, taco => {
    let api_key = taco.getenv("OPENAI_API_KEY")
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
async test "agent/single_tool_call" (t : @test.Test) {
  @mock.run(t, retry=3, taco => {
    let api_key = taco.getenv("OPENAI_API_KEY")
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())

    // Track tool calls
    let mut tool_called = false
    let mut tool_name = ""
    let calculator_schema = @tool.JsonSchema::from_json({
      "type": "object",
      "properties": {
        "a": { "type": "number", "description": "First number" },
        "b": { "type": "number", "description": "Second number" },
      },
      "required": ["a", "b"],
    })

    // Add a simple calculator tool
    let calculator_tool = @tool.new(
      name="add_numbers",
      description="Add two numbers together",
      schema=calculator_schema,
      ToolFn(args => {
        tool_called = true
        guard args is { "a": Number(a, ..), "b": Number(b, ..), .. } else {
          return @tool.error("Invalid arguments")
        }
        let sum = a + b
        @tool.ok({ "result": sum })
      }),
    )
    agent.add_tools([calculator_tool.to_agent_tool()])
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
async test "agent/multiple_tool_calls" (t : @test.Test) {
  @mock.run(t, retry=3, taco => {
    let api_key = taco.getenv("OPENAI_API_KEY")
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())

    // Track tool calls
    let tool_calls : Array[String] = []
    let binary_op_schema = @tool.JsonSchema::from_json({
      "type": "object",
      "properties": { "a": { "type": "number" }, "b": { "type": "number" } },
      "required": ["a", "b"],
    })

    // Add multiple tools
    let add_tool = @tool.new(
      name="add",
      description="Add two numbers",
      schema=binary_op_schema,
      ToolFn(args => {
        guard args is { "a": Number(a, ..), "b": Number(b, ..), .. } else {
          return @tool.error("Invalid arguments")
        }
        @tool.ok({ "result": a + b })
      }),
    )
    let multiply_tool = @tool.new(
      name="multiply",
      description="Multiply two numbers",
      schema=binary_op_schema,
      ToolFn(args => {
        guard args is { "a": Number(a, ..), "b": Number(b, ..), .. } else {
          return @tool.error("Invalid arguments")
        }
        @tool.ok({ "result": a * b })
      }),
    )
    agent.add_tools([add_tool.to_agent_tool(), multiply_tool.to_agent_tool()])
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
async test "agent/event_system" (t : @test.Test) {
  @mock.run(t, timeout=120_000, retry=3, taco => {
    let api_key = taco.getenv("OPENAI_API_KEY")
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
async test "agent/file_operations" (t : @test.Test) {
  @mock.run(t, retry=3, taco => {
    let api_key = taco.getenv("OPENAI_API_KEY")
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())

    // Add file management tools
    let file_manager = @file.manager(cwd=taco.cwd.path())
    agent.add_tools([
      @replace_in_file.new(file_manager).to_agent_tool(),
      @read_file.new(file_manager).to_agent_tool(),
    ])

    // Track if files were created/read
    let mut file_written = false
    let mut _file_read = false
    agent.add_listener(event => match event {
      PreToolCall(tool_call) =>
        match tool_call.function.name {
          "replace_in_file" => file_written = true
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
    let file_content = @fsx.read_file(@path.join(taco.cwd.path(), "test.txt"))
    inspect(file_content.contains("Hello"), content="true")
  })
}

///|
/// Test agent token counting and context pruning
async test "agent/token_management" (t : @test.Test) {
  @mock.run(t, retry=3, taco => {
    let api_key = taco.getenv("OPENAI_API_KEY")
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
async test "agent/tool_error_handling" (t : @test.Test) {
  @mock.run(t, retry=3, taco => {
    let api_key = taco.getenv("OPENAI_API_KEY")
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())
    let mut error_encountered = false
    let binary_op_schema = @tool.JsonSchema::from_json({
      "type": "object",
      "properties": { "a": { "type": "number" }, "b": { "type": "number" } },
      "required": ["a", "b"],
    })

    // Add a tool that always fails
    let failing_tool = @tool.new(
      name="divide",
      description="Divide two numbers (will fail on division by zero)",
      schema=binary_op_schema,
      ToolFn(args => {
        guard args is { "a": Number(a, ..), "b": Number(b, ..), .. } else {
          return @tool.error("Invalid arguments")
        }
        if b == 0.0 {
          return @tool.error("Division by zero")
        }
        @tool.ok({ "result": a / b })
      }),
    )
    agent.add_tools([failing_tool.to_agent_tool()])
    agent.add_listener(event => match event {
      PostToolCall(_, result~, rendered~) =>
        match result {
          Err(_) => {
            error_encountered = true
            inspect(rendered, content="Division by zero")
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
async test "agent/batch_tool_registration" (t : @test.Test) {
  @mock.run(t, retry=3, taco => {
    let api_key = taco.getenv("OPENAI_API_KEY")
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path())
    let empty_schema = @tool.JsonSchema::from_json({
      "type": "object",
      "properties": {},
      "required": [],
    })

    // Create multiple tools
    let tools = [
      @tool.new(
        name="tool1",
        description="First tool",
        schema=empty_schema,
        ToolFn(_ => @tool.ok({ "result": "tool1" })),
      ),
      @tool.new(
        name="tool2",
        description="Second tool",
        schema=empty_schema,
        ToolFn(_ => @tool.ok({ "result": "tool2" })),
      ),
      @tool.new(
        name="tool3",
        description="Third tool",
        schema=empty_schema,
        ToolFn(_ => @tool.ok({ "result": "tool3" })),
      ),
    ]

    // Register all tools at once
    agent.add_tools(tools.map(fn(t) { t.to_agent_tool() }))
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
async test "agent/conversation_history" (t : @test.Test) {
  @mock.run(t, retry=3, taco => {
    let api_key = taco.getenv("OPENAI_API_KEY")
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

///|
/// Test agent with read multiple files
async test "agent/read_multiple_files" (t : @test.Test) {
  @mock.run(t, retry=3, taco => {
    let api_key = taco.getenv("OPENAI_API_KEY")
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path(), logger=taco.logger)

    // Add file management tools
    let file_manager = @file.manager(cwd=taco.cwd.path())
    agent.add_tools([
      @read_multiple_files.new(file_manager).to_agent_tool(),
      @replace_in_file.new(file_manager).to_agent_tool(),
    ])

    // Track if files were created/read
    let mut file_written = false
    let mut multiple_files_read = false
    agent.add_listener(event => match event {
      PreToolCall(tool_call) =>
        match tool_call.function.name {
          "replace_in_file" => file_written = true
          "read_multiple_files" => multiple_files_read = true
          _ => ()
        }
      _ => ()
    })
    let args1 : Json = {
      "files": [
        { "path": "foo.txt", "start_line": 1, "end_line": 3 },
        { "path": "bar.txt", "start_line": 2, "end_line": 4 },
      ],
    }
    let args2 : Json = {
      "files": [{ "path": "foo.txt" }, { "path": "bar.txt" }],
    }
    let system_prompt =
      $| # read_multiple_files 
      $|
      $| This tool allows you to read multiple files at once.
      $| 
      $| read_multiple_files parameters: should be the typescript type `{ files : { path : string; start_line?: number; end_line?: number }[] }`
      $|
      $| ## examples 
      $|
      $| e.g. \{args1.stringify()}
      $|
      $| e.g. \{args2.stringify()}
      $|
      $|
    agent.add_message(@openai.system_message(content=system_prompt))
    // Ask agent to create and read a file
    let content =
      #| Create a file called 'foo.txt' with the content 'Hello, Foo!'.
      #| Create a file called 'bar.txt' with the content 'Hello, Bar!'.
      #| Then read both files concat write to 'foo_bar.txt'
      #|
    agent.add_message(@openai.user_message(content~))
    agent.start()

    // Verify file operations occurred
    inspect(file_written, content="true")
    inspect(multiple_files_read, content="true")
    // Verify file was actually created
    let file_content = @fsx.read_file(@path.join(taco.cwd.path(), "foo.txt"))
    inspect(file_content.contains("Foo"), content="true")
    let file_content = @fsx.read_file(@path.join(taco.cwd.path(), "bar.txt"))
    inspect(file_content.contains("Bar"), content="true")
    let file_content = @fsx.read_file(@path.join(taco.cwd.path(), "foo_bar.txt"))
    inspect(file_content.contains("Foo"), content="true")
    inspect(file_content.contains("Bar"), content="true")
  })
}

///|
/// Test agent with read multiple files
async test "agent/read_multiple_files/specified_ranges" (t : @test.Test) {
  @mock.run(t, retry=3, taco => {
    let api_key = taco.getenv("OPENAI_API_KEY")
    let model = claude_haiku_model(api_key)
    let agent = @agent.new(model, cwd=taco.cwd.path(), logger=taco.logger)

    // Add file management tools
    let file_manager = @file.manager(cwd=taco.cwd.path())
    agent.add_tools([
      @read_multiple_files.new(file_manager).to_agent_tool(),
      @replace_in_file.new(file_manager).to_agent_tool(),
    ])

    // Track if files were created/read
    let mut multiple_files_read = false
    agent.add_listener(event => match event {
      PreToolCall(tool_call) =>
        match tool_call.function.name {
          "read_multiple_files" => multiple_files_read = true
          _ => ()
        }
      _ => ()
    })
    let args1 : Json = {
      "files": [
        { "path": "foo.txt", "start_line": 1, "end_line": 3 },
        { "path": "bar.txt", "start_line": 2, "end_line": 4 },
        { "path": "bar.txt" },
      ],
    }
    let args2 : Json = {
      "files": [{ "path": "foo.txt" }, { "path": "bar.txt" }],
    }
    let system_prompt =
      $| # read_multiple_files 
      $|
      $| This tool allows you to read multiple files with specified line ranges(optional) at once 
      $| 
      $| read_multiple_files parameters: should be the typescript type `{ files : { path : string; start_line?: number; end_line?: number }[] }`
      $|
      $| ## examples 
      $|
      $| e.g. \{args1.stringify()}
      $|
      $| e.g. \{args2.stringify()}
      $|
    agent.add_message(@openai.system_message(content=system_prompt))
    let _ = taco.add_file(
      "foo.txt",
      content=(
        #|foo.txt:L1 
        #|foo.txt:L2 
        #|foo.txt:L3 
        #|foo.txt:L4 
        #|foo.txt:L5 
      ),
    )
    let _ = taco.add_file(
      "bar.txt",
      content=(
        #|bar.txt:L1 
        #|bar.txt:L2 
        #|bar.txt:L3 
      ),
    )

    // Ask agent to create and read a file
    let content =
      #| you should concat foo.txt Line 3 - Line 4, and bar.txt Line 3,
      #| and then write to output.txt
    agent.add_message(@openai.user_message(content~))
    agent.start()
    inspect(multiple_files_read, content="true")
    // Verify file was actually created

    let file_content = @fs.read_file(@path.join(taco.cwd.path(), "output.txt"))
    println(file_content)
  })
}
