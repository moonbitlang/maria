///|
/// Test basic agent initialization and configuration
#skip
async test "agent/initialization" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(model, cwd=mock.cwd.path())

    // Verify agent was created successfully
    inspect(agent.cwd, content=mock.cwd.path())
    inspect(agent.model.name, content="anthropic/claude-haiku-4.5")
    inspect(agent.model.model_name, content="anthropic/claude-haiku-4.5")
  })
}

///|
/// Test agent with a simple message-only interaction (no tools)
#skip
async test "agent/simple_conversation" (t : @test.Test) {
  @mock.run(t, timeout=120_000, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="Say 'Hello, World!' and nothing else.",
    )

    // Track events
    let mut conversation_started = false
    let mut conversation_ended = false
    let mut message_count = 0
    agent.add_listener(event => {
      match event.desc {
        PreConversation => conversation_started = true
        PostConversation => conversation_ended = true
        UserMessage(_) => message_count = message_count + 1
        _ => ()
      }
    })

    // Start the agent
    agent.start()

    // Verify conversation lifecycle
    inspect(conversation_started, content="true")
    // Event timing is async, PostConversation may not be processed immediately
    inspect(message_count > 0, content="true")
    inspect(conversation_ended, content="true")
  })
}

///|
/// Test agent with a simple tool call
#skip
async test "agent/single_tool_call" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="Use the add_numbers tool to calculate 5 + 3. Return only the result.",
    )

    // Track tool calls
    let mut tool_called = false
    let mut tool_name = ""
    let calculator_schema : @tool.JsonSchema = {
      "type": "object",
      "properties": {
        "a": { "type": "number", "description": "First number" },
        "b": { "type": "number", "description": "Second number" },
      },
      "required": ["a", "b"],
    }
    let result = []
    // Add a simple calculator tool
    let calculator_tool = @tool.new(
      name="add_numbers",
      description="Add two numbers together",
      schema=calculator_schema,
      args => {
        tool_called = true
        guard args is { "a": Number(a, ..), "b": Number(b, ..), .. } else {
          return @tool.error("Invalid arguments")
        }
        let sum = a + b
        result.push(sum)
        @tool.ok({ "result": sum })
      },
    )
    agent.add_tools([calculator_tool.to_agent_tool()])
    agent.add_listener(event => {
      match event.desc {
        PreToolCall(tool_call) => tool_name = tool_call.name
        _ => ()
      }
    })
    agent.start()

    // Verify tool was called
    inspect(tool_called, content="true")
    inspect(tool_name, content="add_numbers")
    json_inspect(result, content=[8])
  })
}

///|
/// Test agent with multiple tool calls in sequence
#skip
async test "agent/multiple_tool_calls" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="First use the add tool to calculate 5 + 3, then use the multiply tool to multiply the result by 2. Return the final result.",
    )

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
    agent.add_listener(event => {
      match event.desc {
        PreToolCall(tool_call) => tool_calls.push(tool_call.name)
        _ => ()
      }
    })
    agent.start()

    // Verify both tools were called
    inspect(tool_calls.length() >= 2, content="true")
    inspect(tool_calls.contains("add"), content="true")
    inspect(tool_calls.contains("multiply"), content="true")
  })
}

///|
/// Test agent event system
#skip
async test "agent/event_system" (t : @test.Test) {
  @mock.run(t, timeout=120_000, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="Say 'Testing events' and nothing else.",
    )

    // Track all event types with Ref for async updates
    let mut pre_conversation = false
    let mut post_conversation = false
    let mut message_added = false
    let mut token_counted = false
    let mut assistant_response = false
    agent.add_listener(event => {
      match event.desc {
        PreConversation => pre_conversation = true
        PostConversation => post_conversation = true
        UserMessage(_) => message_added = true
        TokenCounted(_) => token_counted = true
        AssistantMessage(_, ..) => assistant_response = true
        _ => ()
      }
    })
    agent.start()

    // Give events time to process
    // @async.sleep(100)

    // Verify all expected events fired
    inspect(pre_conversation, content="true")
    // Event timing is async, PostConversation may not be processed immediately
    inspect(message_added, content="true")
    inspect(token_counted, content="true")
    inspect(post_conversation, content="true")
    inspect(assistant_response, content="true")
  })
}

///|
/// Test agent with file operations
#skip
async test "agent/file_operations" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="Create a file called 'test.txt' with the content 'Hello, World!' and then read it back to confirm.",
    )

    // Add file management tools
    let file_manager = @file.manager(cwd=mock.cwd.path())
    agent.add_tools([
      @replace_in_file.new(file_manager).to_agent_tool(),
      @read_file.new(file_manager).to_agent_tool(),
    ])

    // Track if files were created/read
    let mut file_written = false
    let mut _file_read = false
    agent.add_listener(event => {
      match event.desc {
        PreToolCall(tool_call) =>
          match tool_call.name {
            "replace_in_file" => file_written = true
            "read_file" => _file_read = true
            _ => ()
          }
        _ => ()
      }
    })
    agent.start()

    // Verify file operations occurred
    inspect(file_written, content="true")

    // Verify file was actually created
    let file_content = @fsx.read_file(@pathx.join(mock.cwd.path(), "test.txt"))
    inspect(file_content.contains("Hello"), content="true")
  })
}

///|
/// Test agent token counting and context pruning
#skip
async test "agent/token_management" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="Say 'Hello' briefly.",
    )
    let mut token_count = 0
    let mut _context_pruned = false
    agent.add_listener(event => {
      match event.desc {
        TokenCounted(count) => token_count = count
        ContextPruned(origin_token_count~, pruned_token_count~) => {
          _context_pruned = true
          inspect(origin_token_count >= pruned_token_count, content="true")
        }
        _ => ()
      }
    })
    agent.start()

    // Verify token counting occurred
    inspect(token_count > 0, content="true")
  })
}

///|
/// Test agent with error handling in tools
#skip
async test "agent/tool_error_handling" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="Use the divide tool to divide 10 by 0. I know that it will fail, but please try to execute the tool anyway.",
    )
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
    agent.add_listener(event => {
      match event.desc {
        PostToolCall(_, result~, rendered~) =>
          match result {
            Err(_) => {
              error_encountered = true
              inspect(rendered, content="Division by zero")
            }
            _ => ()
          }
        _ => ()
      }
    })
    agent.start()

    // Verify error was handled
    inspect(error_encountered, content="true")
  })
}

///|
let empty_schema : @tool.JsonSchema = @tool.JsonSchema::from_json({
  "type": "object",
  "properties": {},
  "required": [],
})

///|
/// Test agent with batch tool registration
#skip
async test "agent/batch_tool_registration" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="I have three tools available: tool1, tool2, and tool3. Please call tool1.",
    )

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
    agent.add_listener(event => {
      match event.desc {
        PreToolCall(tool_call) => tool_names.push(tool_call.name)
        _ => ()
      }
    })
    agent.start()

    // Verify at least one tool was available and called
    inspect(tool_names.length() > 0, content="true")
  })
}

///|
/// Test agent conversation history persistence
#skip
async test "agent/conversation_history" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message=(
        $|You are a helpful assistant.
        $|Say 'Hello' and nothing else.
        $|
      ),
    )
    let mut message_count = 0
    agent.add_listener(event => {
      match event.desc {
        UserMessage(_) => message_count = message_count + 1
        _ => ()
      }
    })
    agent.start()

    // Verify messages were tracked
    assert_true(message_count >= 1)
  })
}

///|
/// Test agent with read multiple files
#skip
async test "agent/read_multiple_files" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
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
    let content =
      #| Create a file called 'foo.txt' with the content 'Hello, Foo!'.
      #| Create a file called 'bar.txt' with the content 'Hello, Bar!'.
      #| Then read both files concat write to 'foo_bar.txt'
      #|
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      logger=mock.logger,
      system_message=system_prompt,
      user_message=content,
    )

    // Add file management tools
    let file_manager = @file.manager(cwd=mock.cwd.path())
    agent.add_tools([
      @read_multiple_files.new(file_manager).to_agent_tool(),
      @replace_in_file.new(file_manager).to_agent_tool(),
    ])

    // Track if files were created/read
    let mut file_written = false
    let mut multiple_files_read = false
    agent.add_listener(event => {
      match event.desc {
        PreToolCall(tool_call) =>
          match tool_call.name {
            "replace_in_file" => file_written = true
            "read_multiple_files" => multiple_files_read = true
            _ => ()
          }
        _ => ()
      }
    })
    agent.start()

    // Verify file operations occurred
    inspect(file_written, content="true")
    inspect(multiple_files_read, content="true")
    // Verify file was actually created
    let file_content = @fsx.read_file(@pathx.join(mock.cwd.path(), "foo.txt"))
    inspect(file_content.contains("Foo"), content="true")
    let file_content = @fsx.read_file(@pathx.join(mock.cwd.path(), "bar.txt"))
    inspect(file_content.contains("Bar"), content="true")
    let file_content = @fsx.read_file(
      @pathx.join(mock.cwd.path(), "foo_bar.txt"),
    )
    inspect(file_content.contains("Foo"), content="true")
    inspect(file_content.contains("Bar"), content="true")
  })
}

///|
#skip
async test "load-model-name" (t : @test.Test) {
  @mock.run(t, mock => {
    let api_key = mock.getenv("OPENAI_API_KEY")
    let model = @model.new(
      api_key~,
      base_url="https://openrouter.ai/api/v1",
      name="haiku",
      model_name="anthropic/claude-haiku-4.5",
      safe_zone_tokens=200000,
    )
    let models = [model]
    let models_file = mock.cwd
      .add_directory(".moonagent")
      .add_directory("models")
      .add_file("models.json")
    models_file.write_string(models.to_json().stringify(indent=2))
    json_inspect(mock.json(@json.parse(models_file.read())), content=[
      {
        "name": "haiku",
        "model_name": "anthropic/claude-haiku-4.5",
        "model_type": "saas/openai",
        "api_key": "(mock:env:OPENAI_API_KEY)",
        "base_url": "https://openrouter.ai/api/v1",
        "safe_zone_tokens": 200000,
        "supports_anthropic_prompt_caching": false,
        "supports_apply_patch": false,
      },
    ])
    @agent.new(
      model,
      cwd=mock.cwd.path(),
      logger=mock.logger,
      user_message="Say 'Hello from loaded model' and nothing else.",
    ).start()
  })
}

///|
#skip
async test "agent/queue_message" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
      user_message="Hello!",
    )
    json_inspect(
      agent.queue_message(@ai.user_message(content="How are you?")),
      content="42858c8d-3684-43ab-837d-ef6894a9b8dc",
    )
    json_inspect(
      agent.queue_message(@ai.user_message(content="Thank you")),
      content="aaa2f959-3b7f-4ace-870e-0f67cb28ebe3",
    )
    let message_unqueued = []
    agent.add_listener(event => {
      match event.desc {
        MessageUnqueued(id~) => message_unqueued.push(id)
        _ => ()
      }
    })
    agent.start()
    json_inspect(message_unqueued, content=[
      "42858c8d-3684-43ab-837d-ef6894a9b8dc", "aaa2f959-3b7f-4ace-870e-0f67cb28ebe3",
    ])
  })
}

///|
#skip
async test "agent/set_enabled_tools" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="Can you please submit a list of available tools to me using the <submit_available_tools> tool?",
    )
    let mut result = Json::null()
    agent.add_tools([
      @tool.new(
        name="tool1",
        description="First tool",
        schema=empty_schema,
        ToolFn(_ => @tool.ok({ "result": "tool1" })),
      ).to_agent_tool(),
      @tool.new(
        name="tool2",
        description="Second tool",
        schema=empty_schema,
        ToolFn(_ => @tool.ok({ "result": "tool2" })),
      ).to_agent_tool(),
      @tool.new(
        name="tool3",
        description="Third tool",
        schema=empty_schema,
        ToolFn(_ => @tool.ok({ "result": "tool3" })),
      ).to_agent_tool(),
      @tool.new(
        name="submit_available_tools",
        description="Submit a list of available tools to user. You should exclude this tool (submit_available_tools) from the list.",
        schema=@tool.JsonSchema::from_json({
          "type": "object",
          "properties": {
            "tools": { "type": "array", "items": { "type": "string" } },
          },
          "required": ["tools"],
        }),
        ToolFn(args => {
          result = args
          @tool.ok("Tools submitted successfully")
        }),
      ).to_agent_tool(),
    ])
    agent.start()
    json_inspect(result, content={ "tools": ["tool1", "tool2", "tool3"] })
    result = Json::null()
    agent.set_enabled_tools(
      Set::from_array(["tool1", "tool2", "submit_available_tools"]),
    )
    agent.queue_message(
      @ai.user_message(
        content="Can you please check which tools are available again, and submit the list to me using the submit_available_tools again?",
      ),
    )
    |> ignore()
    agent.start()
    json_inspect(result, content={ "tools": ["tool1", "tool2"] })
  })
}

///|
#skip
#cfg(false)
async test "agent/web_search" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(model, cwd=mock.cwd.path())
    let mut result = Json::null()
    agent.add_tool(
      @tool.new(
        name="submit_moonbit_initiation_year",
        description="Submit the year MoonBit was initiated.",
        schema={
          "type": "object",
          "properties": { "year": { "type": "string" } },
          "required": ["year"],
        },
        args => {
          result = args
          @tool.ok("Year submitted successfully")
        },
      ),
    )
    agent.queue_message(
      @ai.user_message(
        content="Can you please search the web for MoonBit to find out which year it is initiated, and submit the year using the submit_moonbit_initiation_year tool?",
      ),
      web_search=true,
    )
    |> ignore()
    agent.start()
    json_inspect(result is { "year": "2022" | "2023", .. }, content=true)
  })
}

///|
async test "agent/resume" (t : @test.Test) {
  @mock.run(t, mock => {
    let cwd = mock.cwd
    let model = mock.model(name=ClaudeHaiku4_5)
    let id = {
      let agent = @agent.new(
        model,
        home=cwd.path(),
        cwd=cwd.path(),
        user_message="Hello, please call me Mr. Rabbit.",
      )
      defer agent.close()
      let id = agent.id()
      agent.start()
      id
    }
    let session_manager = @conversation.Manager::new(
      uuid=mock.uuid,
      clock=mock.clock,
      home=cwd.path(),
    )
    let conversation = session_manager.load(id)
    guard conversation is Some(conversation) else {
      fail("Conversation not found")
    }
    let mut result = None
    let agent = @agent.load(
      model,
      conversation,
      user_message="What is my name? Please use the <submit_user_name/> tool to submit my name.",
    )
    agent.add_tool(
      @tool.new(
        name="submit_user_name",
        description="Submit the user's name.",
        schema=@tool.JsonSchema::from_json({
          "type": "object",
          "properties": { "name": { "type": "string" } },
          "required": ["name"],
        }),
        ToolFn(args => {
          guard args is { "name": String(name), .. } else {
            return @tool.error("Invalid arguments")
          }
          result = Some(name)
          @tool.ok("Name submitted successfully")
        }),
      ),
    )
    agent.start()
    json_inspect(
      result is Some(content) && content.contains("Rabbit"),
      content=true,
    )
  })
}
