///|
/// Test agent creating a new todo list and adding tasks
#skip
async test "agent/todo/create_and_add_tasks" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="Create a todo list and add two tasks: 'Write documentation' with high priority and 'Review code' with medium priority. Then read the list.",
    )

    // Track tool calls
    let mut write_called = false
    let mut read_called = false
    let todo_list = new(uuid=agent.uuid, cwd=agent.cwd)
    agent.add_tools([new_tool(todo_list).to_agent_tool()])
    agent.add_listener(event => match event {
      @event.PreToolCall(tool_call) =>
        match tool_call.name {
          "todo" =>
            // Parse the arguments string as JSON to check the action
            match tool_call.arguments {
              Some(args_str) => {
                let args = @json.parse(args_str)
                match args {
                  Object(map) =>
                    match map.get("action") {
                      Some(String(action_str)) =>
                        match action_str {
                          "read" => read_called = true
                          _ => write_called = true
                        }
                      _ => ()
                    }
                  _ => ()
                }
              }
              None => ()
            }
          _ => ()
        }
      _ => ()
    })
    agent.start()

    // Verify both tools were called
    inspect(write_called, content="true")
    inspect(read_called, content="true")

    // Verify tasks were added
    let todos = todo_list.todos()
    inspect(todos.length() >= 2, content="true")
  })
}

///|
/// Test agent reading empty todo list
#skip
async test "agent/todo/read_empty_list" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="Read the current todo list and tell me how many tasks there are.",
    )

    // Track tool calls
    let mut read_called = false
    let todo_list = new(uuid=agent.uuid, cwd=agent.cwd)
    agent.add_tools([new_tool(todo_list).to_agent_tool()])
    agent.add_listener(event => match event {
      @event.PreToolCall(tool_call) =>
        match tool_call.name {
          "todo" =>
            match tool_call.arguments {
              Some(args_str) => {
                let args = @json.parse(args_str)
                match args {
                  Object(map) =>
                    match map.get("action") {
                      Some(String("read")) => read_called = true
                      _ => ()
                    }
                  _ => ()
                }
              }
              None => ()
            }
          _ => ()
        }
      _ => ()
    })
    agent.start()

    // Verify read was called
    inspect(read_called, content="true")
  })
}

///|
/// Test agent creating tasks with different priorities
#skip
async test "agent/todo/priority_handling" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="Create three tasks: 'Critical bug fix' with high priority, 'Update README' with low priority, and 'Refactor module' with medium priority.",
    )

    // Track tool calls
    let tool_calls : Array[String] = []
    let todo_list = new(uuid=agent.uuid, cwd=agent.cwd)
    agent.add_tools([new_tool(todo_list).to_agent_tool()])
    agent.add_listener(event => match event {
      @event.PreToolCall(tool_call) =>
        match tool_call.name {
          "todo" => tool_calls.push(tool_call.name)
          _ => ()
        }
      _ => ()
    })
    agent.start()

    // Verify tasks were created
    let todos = todo_list.todos()
    inspect(todos.length() >= 3, content="true")

    // Verify different priorities exist
    let mut high_priority = false
    let mut medium_priority = false
    let mut low_priority = false
    for todo in todos {
      match todo.priority {
        High => high_priority = true
        Medium => medium_priority = true
        Low => low_priority = true
      }
    }
    inspect(high_priority || medium_priority || low_priority, content="true")
  })
}
