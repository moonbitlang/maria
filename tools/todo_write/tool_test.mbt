///|
async test "todo_write/create/plain" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": (
        #|Test todo item
        #|Another test item
      ),
      "priority": "high",
    })
    @json.inspect(result, content=[
      "Ok",
      {
        "todos": [
          {
            "content": "Test todo item",
            "created_at": "Tick:3",
            "id": "ac8a366d",
            "priority": "High",
            "status": "Pending",
            "updated_at": "Tick:3",
          },
          {
            "content": "Another test item",
            "created_at": "Tick:4",
            "id": "1ea1417c",
            "priority": "High",
            "status": "Pending",
            "updated_at": "Tick:4",
          },
        ],
        "message": "Created 2 new todo items",
        "updated_todos": [
          {
            "content": "Test todo item",
            "created_at": "Tick:3",
            "id": "ac8a366d",
            "priority": "High",
            "status": "Pending",
            "updated_at": "Tick:3",
          },
          {
            "content": "Another test item",
            "created_at": "Tick:4",
            "id": "1ea1417c",
            "priority": "High",
            "status": "Pending",
            "updated_at": "Tick:4",
          },
        ],
        "is_new_creation": true,
      },
    ])
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Created 2 new todo items
        #|
        #|📝 Newly created todos:
        #|  🔴 ⏳ [ac8a366d] Test todo item
        #|  🔴 ⏳ [1ea1417c] Another test item
        #|
        #|📊 Current summary: Total 2 items | Pending 2 | In Progress 0 | Completed 0
      ),
    )
  })
}

///|
async test "todo_write/create/<task>" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": (
        #|<task>Examine reference repository structure at .moonagent/repos/ini</task>
        #|<task>Examine current MoonBit project structure</task>
        #|<task>Analyze source files in ini repository</task>
        #|<task>Plan migration strategy preserving original structure</task>
        #|<task>Translate C/C++ files to MoonBit file-by-file</task>
        #|<task>Create appropriate MoonBit module structure</task>
        #|<task>Test migrated functionality</task>
      ),
    })
    @json.inspect(result, content=[
      "Ok",
      {
        "todos": [
          {
            "content": "Examine reference repository structure at .moonagent/repos/ini",
            "created_at": "Tick:3",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:3",
          },
          {
            "content": "Examine current MoonBit project structure",
            "created_at": "Tick:4",
            "id": "1ea1417c",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:4",
          },
          {
            "content": "Analyze source files in ini repository",
            "created_at": "Tick:5",
            "id": "f378dd8d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:5",
          },
          {
            "content": "Plan migration strategy preserving original structure",
            "created_at": "Tick:6",
            "id": "42858c8d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:6",
          },
          {
            "content": "Translate C/C++ files to MoonBit file-by-file",
            "created_at": "Tick:7",
            "id": "1258fdc0",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:7",
          },
          {
            "content": "Create appropriate MoonBit module structure",
            "created_at": "Tick:8",
            "id": "aaa2f959",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:8",
          },
          {
            "content": "Test migrated functionality",
            "created_at": "Tick:9",
            "id": "8f0ff2dc",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:9",
          },
        ],
        "message": "Created 7 new todo items",
        "updated_todos": [
          {
            "content": "Examine reference repository structure at .moonagent/repos/ini",
            "created_at": "Tick:3",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:3",
          },
          {
            "content": "Examine current MoonBit project structure",
            "created_at": "Tick:4",
            "id": "1ea1417c",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:4",
          },
          {
            "content": "Analyze source files in ini repository",
            "created_at": "Tick:5",
            "id": "f378dd8d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:5",
          },
          {
            "content": "Plan migration strategy preserving original structure",
            "created_at": "Tick:6",
            "id": "42858c8d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:6",
          },
          {
            "content": "Translate C/C++ files to MoonBit file-by-file",
            "created_at": "Tick:7",
            "id": "1258fdc0",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:7",
          },
          {
            "content": "Create appropriate MoonBit module structure",
            "created_at": "Tick:8",
            "id": "aaa2f959",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:8",
          },
          {
            "content": "Test migrated functionality",
            "created_at": "Tick:9",
            "id": "8f0ff2dc",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:9",
          },
        ],
        "is_new_creation": true,
      },
    ])
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Created 7 new todo items
        #|
        #|📝 Newly created todos:
        #|  🟡 ⏳ [ac8a366d] Examine reference repository structure at .moonagent/repos/ini
        #|  🟡 ⏳ [1ea1417c] Examine current MoonBit project structure
        #|  🟡 ⏳ [f378dd8d] Analyze source files in ini repository
        #|  🟡 ⏳ [42858c8d] Plan migration strategy preserving original structure
        #|  🟡 ⏳ [1258fdc0] Translate C/C++ files to MoonBit file-by-file
        #|  🟡 ⏳ [aaa2f959] Create appropriate MoonBit module structure
        #|  🟡 ⏳ [8f0ff2dc] Test migrated functionality
        #|
        #|📊 Current summary: Total 7 items | Pending 7 | In Progress 0 | Completed 0
      ),
    )
  })
}

///|
async test "todo_write/update" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": (
        #|First item
        #|Second item
      ),
      "priority": "medium",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Created 2 new todo items
        #|
        #|📝 Newly created todos:
        #|  🟡 ⏳ [ac8a366d] First item
        #|  🟡 ⏳ [1ea1417c] Second item
        #|
        #|📊 Current summary: Total 2 items | Pending 2 | In Progress 0 | Completed 0
      ),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "update",
      "task_id": "ac8a366d",
      "status": "in-progress",
      "priority": "high",
      "content": "Updated first item",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Updated task: Updated first item
        #|
        #|📝 Current todo list:
        #|  🔴 🔄 [ac8a366d] Updated first item
        #|  🟡 ⏳ [1ea1417c] Second item
        #|
        #|✨ Updated items:
        #|  🔴 🔄 [ac8a366d] Updated first item
        #|
        #|📊 Current summary: Total 2 items | Pending 1 | In Progress 1 | Completed 0
      ),
    )
  })
}

///|
async test "todo_write/mark_completed" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": (
        #|First item
        #|Second item
      ),
      "priority": "medium",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Created 2 new todo items
        #|
        #|📝 Newly created todos:
        #|  🟡 ⏳ [ac8a366d] First item
        #|  🟡 ⏳ [1ea1417c] Second item
        #|
        #|📊 Current summary: Total 2 items | Pending 2 | In Progress 0 | Completed 0
      ),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "mark_completed",
      "task_id": "nonexistent",
    })
    @json.inspect(result, content=[
      "Error",
      ["ToolFailure", "Error: Task with ID 'nonexistent' not found."],
      "Error: Task with ID 'nonexistent' not found.",
    ])
    let result = @todo_write.new(todo_list).call({
      "action": "mark_completed",
      "task_id": "ac8a366d",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Marked task as completed: First item
        #|
        #|📝 Current todo list:
        #|  🟡 ✅ [ac8a366d] First item
        #|  🟡 ⏳ [1ea1417c] Second item
        #|
        #|✨ Updated items:
        #|  🟡 ✅ [ac8a366d] First item
        #|
        #|📊 Current summary: Total 2 items | Pending 1 | In Progress 0 | Completed 1
      ),
    )
  })
}

///|
async test "todo_write/mark_progress" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": (
        #|First item
        #|Second item
      ),
      "priority": "medium",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Created 2 new todo items
        #|
        #|📝 Newly created todos:
        #|  🟡 ⏳ [ac8a366d] First item
        #|  🟡 ⏳ [1ea1417c] Second item
        #|
        #|📊 Current summary: Total 2 items | Pending 2 | In Progress 0 | Completed 0
      ),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "mark_progress",
      "task_id": "nonexistent",
    })
    @json.inspect(result, content=[
      "Error",
      ["ToolFailure", "Error: Task with ID 'nonexistent' not found."],
      "Error: Task with ID 'nonexistent' not found.",
    ])
    inspect(result, content="Error: Task with ID 'nonexistent' not found.")
    let result = @todo_write.new(todo_list).call({
      "action": "mark_progress",
      "task_id": "ac8a366d",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Marked task as in progress: First item
        #|
        #|📝 Current todo list:
        #|  🟡 🔄 [ac8a366d] First item
        #|  🟡 ⏳ [1ea1417c] Second item
        #|
        #|✨ Updated items:
        #|  🟡 🔄 [ac8a366d] First item
        #|
        #|📊 Current summary: Total 2 items | Pending 1 | In Progress 1 | Completed 0
      ),
    )
  })
}

///|
async test "todo_write/add_task" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    // Create initial list
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": "Initial task",
      "priority": "medium",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Add a new task
    let result = @todo_write.new(todo_list).call({
      "action": "add_task",
      "content": "Additional task to be added",
      "priority": "high",
      "status": "pending",
      "notes": "This is a very important task",
    })
    @json.inspect(result, content=[
      "Ok",
      {
        "todos": [
          {
            "content": "Initial task",
            "created_at": "Tick:3",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:3",
          },
          {
            "content": "Additional task to be added",
            "created_at": "Tick:5",
            "id": "1ea1417c",
            "notes": "This is a very important task",
            "priority": "High",
            "status": "Pending",
            "updated_at": "Tick:5",
          },
        ],
        "message": "Added new task: Additional task to be added",
        "updated_todos": [
          {
            "content": "Additional task to be added",
            "created_at": "Tick:5",
            "id": "1ea1417c",
            "notes": "This is a very important task",
            "priority": "High",
            "status": "Pending",
            "updated_at": "Tick:5",
          },
        ],
        "is_new_creation": false,
      },
    ])
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Added new task: Additional task to be added
        #|
        #|📝 Current todo list:
        #|  🟡 ⏳ [ac8a366d] Initial task
        #|  🔴 ⏳ [1ea1417c] Additional task to be added
        #|
        #|✨ Updated items:
        #|  🔴 ⏳ [1ea1417c] Additional task to be added
        #|
        #|📊 Current summary: Total 2 items | Pending 2 | In Progress 0 | Completed 0
      ),
    )
  })
}

///|
async test "todo_write/multiple_priority_levels" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": (
        #|High priority task
        #|Medium priority task
        #|Low priority task
      ),
      "priority": "high",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Created 3 new todo items
        #|
        #|📝 Newly created todos:
        #|  🔴 ⏳ [ac8a366d] High priority task
        #|  🔴 ⏳ [1ea1417c] Medium priority task
        #|  🔴 ⏳ [f378dd8d] Low priority task
        #|
        #|📊 Current summary: Total 3 items | Pending 3 | In Progress 0 | Completed 0
      ),
    )
    // Update priorities
    let result = @todo_write.new(todo_list).call({
      "action": "update",
      "task_id": "1ea1417c",
      "priority": "medium",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    let result = @todo_write.new(todo_list).call({
      "action": "update",
      "task_id": "f378dd8d",
      "priority": "low",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Updated task: Low priority task
        #|
        #|📝 Current todo list:
        #|  🔴 ⏳ [ac8a366d] High priority task
        #|  🟡 ⏳ [1ea1417c] Medium priority task
        #|  🟢 ⏳ [f378dd8d] Low priority task
        #|
        #|✨ Updated items:
        #|  🟢 ⏳ [f378dd8d] Low priority task
        #|
        #|📊 Current summary: Total 3 items | Pending 3 | In Progress 0 | Completed 0
      ),
    )
  })
}

///|
async test "todo_write/workflow_complete_cycle" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    // Create tasks
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": (
        #|Design API endpoints
        #|Implement backend logic
        #|Write tests
        #|Deploy to production
      ),
      "priority": "high",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Start first task
    let result = @todo_write.new(todo_list).call({
      "action": "mark_progress",
      "task_id": "ac8a366d",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Complete first task
    let result = @todo_write.new(todo_list).call({
      "action": "mark_completed",
      "task_id": "ac8a366d",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Start second task
    let result = @todo_write.new(todo_list).call({
      "action": "mark_progress",
      "task_id": "1ea1417c",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Complete second task
    let result = @todo_write.new(todo_list).call({
      "action": "mark_completed",
      "task_id": "1ea1417c",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Marked task as completed: Implement backend logic
        #|
        #|📝 Current todo list:
        #|  🔴 ✅ [ac8a366d] Design API endpoints
        #|  🔴 ✅ [1ea1417c] Implement backend logic
        #|  🔴 ⏳ [f378dd8d] Write tests
        #|  🔴 ⏳ [42858c8d] Deploy to production
        #|
        #|✨ Updated items:
        #|  🔴 ✅ [1ea1417c] Implement backend logic
        #|
        #|📊 Current summary: Total 4 items | Pending 2 | In Progress 0 | Completed 2
      ),
    )
  })
}

///|
async test "todo_write/error_invalid_action" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "invalid_action",
      "content": "Test task",
    })
    @json.inspect(result, content=[
      "Error",
      [
        "ToolFailure", "Error: Invalid action 'invalid_action'. Supported actions: create, add_task, update, mark_progress, mark_completed.",
      ],
      "Error: Invalid action 'invalid_action'. Supported actions: create, add_task, update, mark_progress, mark_completed.",
    ])
    inspect(
      result,
      content="Error: Invalid action 'invalid_action'. Supported actions: create, add_task, update, mark_progress, mark_completed.",
    )
  })
}

///|
async test "todo_write/error_missing_content_for_create" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({ "action": "create" })
    @json.inspect(result, content=[
      "Error",
      ["ToolFailure", "Error: Content is required for creating todos."],
      "Error: Content is required for creating todos.",
    ])
    inspect(result, content="Error: Content is required for creating todos.")
  })
}

///|
async test "todo_write/error_missing_content_for_add_task" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({ "action": "add_task" })
    @json.inspect(result, content=[
      "Error",
      ["ToolFailure", "Error: Content is required for adding a task."],
      "Error: Content is required for adding a task.",
    ])
    inspect(result, content="Error: Content is required for adding a task.")
  })
}

///|
async test "todo_write/error_missing_task_id_for_update" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "update",
      "content": "New content",
    })
    @json.inspect(result, content=[
      "Error",
      ["ToolFailure", "Error: Task ID is required for update operations."],
      "Error: Task ID is required for update operations.",
    ])
    inspect(result, content="Error: Task ID is required for update operations.")
  })
}

///|
async test "todo_write/error_invalid_priority" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": "Test task",
      "priority": "urgent",
    })
    @json.inspect(result, content=[
      "Error",
      [
        "ToolFailure", "Error: Invalid priority 'String(\"urgent\")'. Must be 'high', 'medium', or 'low'.",
      ],
      "Error: Invalid priority 'String(\"urgent\")'. Must be 'high', 'medium', or 'low'.",
    ])
    inspect(
      result,
      content=(
        #|Error: Invalid priority 'String("urgent")'. Must be 'high', 'medium', or 'low'.
      ),
    )
  })
}

///|
async test "todo_write/error_invalid_status" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": "Test task",
      "status": "done",
    })
    @json.inspect(result, content=[
      "Error",
      [
        "ToolFailure", "Error: Invalid status 'String(\"done\")'. Must be 'pending', 'in_progress', or 'completed'.",
      ],
      "Error: Invalid status 'String(\"done\")'. Must be 'pending', 'in_progress', or 'completed'.",
    ])
    inspect(
      result,
      content=(
        #|Error: Invalid status 'String("done")'. Must be 'pending', 'in_progress', or 'completed'.
      ),
    )
  })
}

///|
async test "todo_write/update_with_notes" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    // Create initial task
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": "Implement feature X",
      "priority": "high",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Update with notes
    let result = @todo_write.new(todo_list).call({
      "action": "update",
      "task_id": "ac8a366d",
      "notes": "Need to consider edge cases and backward compatibility",
      "status": "in_progress",
    })
    @json.inspect(result, content=[
      "Ok",
      {
        "todos": [
          {
            "content": "Implement feature X",
            "created_at": "Tick:3",
            "id": "ac8a366d",
            "notes": "Need to consider edge cases and backward compatibility",
            "priority": "Medium",
            "status": "InProgress",
            "updated_at": "Tick:5",
          },
        ],
        "message": "Updated task: Implement feature X",
        "updated_todos": [
          {
            "content": "Implement feature X",
            "created_at": "Tick:3",
            "id": "ac8a366d",
            "notes": "Need to consider edge cases and backward compatibility",
            "priority": "Medium",
            "status": "InProgress",
            "updated_at": "Tick:5",
          },
        ],
        "is_new_creation": false,
      },
    ])
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Updated task: Implement feature X
        #|
        #|📝 Current todo list:
        #|  🟡 🔄 [ac8a366d] Implement feature X
        #|
        #|✨ Updated items:
        #|  🟡 🔄 [ac8a366d] Implement feature X
        #|
        #|📊 Current summary: Total 1 items | Pending 0 | In Progress 1 | Completed 0
      ),
    )
  })
}

///|
async test "todo_write/update_content_only" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    // Create initial task
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": "Original task description",
      "priority": "medium",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Update content only
    let result = @todo_write.new(todo_list).call({
      "action": "update",
      "task_id": "ac8a366d",
      "content": "Updated task description with more details",
    })
    @json.inspect(result, content=[
      "Ok",
      {
        "todos": [
          {
            "content": "Updated task description with more details",
            "created_at": "Tick:3",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:5",
          },
        ],
        "message": "Updated task: Updated task description with more details",
        "updated_todos": [
          {
            "content": "Updated task description with more details",
            "created_at": "Tick:3",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "Tick:5",
          },
        ],
        "is_new_creation": false,
      },
    ])
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Updated task: Updated task description with more details
        #|
        #|📝 Current todo list:
        #|  🟡 ⏳ [ac8a366d] Updated task description with more details
        #|
        #|✨ Updated items:
        #|  🟡 ⏳ [ac8a366d] Updated task description with more details
        #|
        #|📊 Current summary: Total 1 items | Pending 1 | In Progress 0 | Completed 0
      ),
    )
  })
}

///|
async test "todo_write/add_task_with_in_progress_status" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    // Create initial list
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": "First task",
      "priority": "medium",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Add a new task directly as in-progress
    let result = @todo_write.new(todo_list).call({
      "action": "add_task",
      "content": "Urgent task to start immediately",
      "priority": "high",
      "status": "in-progress",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Added new task: Urgent task to start immediately
        #|
        #|📝 Current todo list:
        #|  🟡 ⏳ [ac8a366d] First task
        #|  🔴 🔄 [1ea1417c] Urgent task to start immediately
        #|
        #|✨ Updated items:
        #|  🔴 🔄 [1ea1417c] Urgent task to start immediately
        #|
        #|📊 Current summary: Total 2 items | Pending 1 | In Progress 1 | Completed 0
      ),
    )
  })
}

///|
async test "todo_write/create_with_low_priority" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": (
        #|Clean up code comments
        #|Update documentation
        #|Refactor utility functions
      ),
      "priority": "low",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Created 3 new todo items
        #|
        #|📝 Newly created todos:
        #|  🟢 ⏳ [ac8a366d] Clean up code comments
        #|  🟢 ⏳ [1ea1417c] Update documentation
        #|  🟢 ⏳ [f378dd8d] Refactor utility functions
        #|
        #|📊 Current summary: Total 3 items | Pending 3 | In Progress 0 | Completed 0
      ),
    )
  })
}

///|
async test "todo_write/mark_completed_then_reopen" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    // Create task
    let result = @todo_write.new(todo_list).call({
      "action": "create",
      "content": "Task that needs rework",
      "priority": "high",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Mark as completed
    let result = @todo_write.new(todo_list).call({
      "action": "mark_completed",
      "task_id": "ac8a366d",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Reopen task by updating status back to pending
    let result = @todo_write.new(todo_list).call({
      "action": "update",
      "task_id": "ac8a366d",
      "status": "pending",
      "notes": "Found issues, needs rework",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|✅ Operation completed: Updated task: Task that needs rework
        #|
        #|📝 Current todo list:
        #|  🟡 ⏳ [ac8a366d] Task that needs rework
        #|
        #|✨ Updated items:
        #|  🟡 ⏳ [ac8a366d] Task that needs rework
        #|
        #|📊 Current summary: Total 1 items | Pending 1 | In Progress 0 | Completed 0
      ),
    )
  })
}
