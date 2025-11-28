///| Tests for todo tool

///|
async test "todo/read/empty" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let todo_tool = @todo_tools.new(todo_list)
    let result = todo_tool.call({ "action": "read" })
    @json.inspect(result, content=["Ok", { "todos": [] }])
    inspect(
      result,
      content=(
        #|=== Current Session Todo List ===
        #|
        #|
        #|📊 Summary: Total: 0
      ),
    )
  })
}

///|
async test "todo/read/single_task" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let todo_tool = @todo_tools.new(todo_list)
    let _ = todo_tool.call({
      "action": "create",
      "content": "A sample task",
      "priority": "medium",
    })
    let result = todo_tool.call({ "action": "read" })
    @json.inspect(
      result
      .to_json()
      .transform(@json.Replacer::exclude(["created_at", "updated_at", "id"])),
      content=[
        "Ok",
        {
          "todos": [
            {
              "content": "A sample task",
              "priority": "Medium",
              "status": "Pending",
            },
          ],
        },
      ],
    )
    inspect(
      result,
      content=(
        #|=== Current Session Todo List ===
        #|
        #|1. ⏳ 🟡 [ac8a366d] A sample task
        #|
        #|📊 Summary: Total: 1 | ⏳ Pending: 1
      ),
    )
  })
}

///|
async test "todo/read/multiple_tasks_mixed_status" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let todo_tool = @todo_tools.new(todo_list)

    // Create multiple tasks
    let _ = todo_tool.call({
      "action": "create",
      "content": (
        #|Task one
        #|Task two
        #|Task three
      ),
      "priority": "high",
    })

    // Mark first task as in-progress
    let _ = todo_tool.call({ "action": "mark_progress", "task_id": "ac8a366d" })

    // Mark second task as completed
    let _ = todo_tool.call({
      "action": "mark_completed",
      "task_id": "1ea1417c",
    })
    let result = todo_tool.call({ "action": "read" })
    @json.inspect(
      result
      .to_json()
      .transform(@json.Replacer::exclude(["created_at", "updated_at", "id"])),
      content=[
        "Ok",
        {
          "todos": [
            {
              "content": "Task one",
              "priority": "High",
              "status": "InProgress",
            },
            { "content": "Task two", "priority": "High", "status": "Completed" },
            { "content": "Task three", "priority": "High", "status": "Pending" },
          ],
        },
      ],
    )
    inspect(
      result,
      content=(
        #|=== Current Session Todo List ===
        #|
        #|1. 🔄 🔴 [ac8a366d] Task one
        #|2. ✅ 🔴 [1ea1417c] Task two
        #|3. ⏳ 🔴 [f378dd8d] Task three
        #|
        #|📊 Summary: Total: 3 | ✅ Completed: 1 | 🔄 In Progress: 1 | ⏳ Pending: 1
      ),
    )
  })
}

///|
async test "todo/read/different_priorities" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let todo_tool = @todo_tools.new(todo_list)

    // Create tasks with different priorities
    let _ = todo_tool.call({
      "action": "create",
      "content": (
        #|High priority task
        #|Medium priority task
        #|Low priority task
      ),
      "priority": "high",
    })

    // Update priorities individually
    let _ = todo_tool.call({
      "action": "update",
      "task_id": "1ea1417c",
      "priority": "medium",
    })
    let _ = todo_tool.call({
      "action": "update",
      "task_id": "f378dd8d",
      "priority": "low",
    })
    let result = todo_tool.call({ "action": "read" })
    @json.inspect(
      result
      .to_json()
      .transform(@json.Replacer::exclude(["created_at", "updated_at", "id"])),
      content=[
        "Ok",
        {
          "todos": [
            {
              "content": "High priority task",
              "priority": "High",
              "status": "Pending",
            },
            {
              "content": "Medium priority task",
              "priority": "Medium",
              "status": "Pending",
            },
            {
              "content": "Low priority task",
              "priority": "Low",
              "status": "Pending",
            },
          ],
        },
      ],
    )
    inspect(
      result,
      content=(
        #|=== Current Session Todo List ===
        #|
        #|1. ⏳ 🔴 [ac8a366d] High priority task
        #|2. ⏳ 🟡 [1ea1417c] Medium priority task
        #|3. ⏳ 🟢 [f378dd8d] Low priority task
        #|
        #|📊 Summary: Total: 3 | ⏳ Pending: 3
      ),
    )
  })
}

///|
async test "todo/read/with_notes" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let todo_tool = @todo_tools.new(todo_list)

    // Create tasks
    let _ = todo_tool.call({
      "action": "create",
      "content": (
        #|Task with notes
        #|Task without notes
      ),
      "priority": "medium",
    })

    // Add notes to first task and change second priority
    let _ = todo_tool.call({
      "action": "update",
      "task_id": "ac8a366d",
      "notes": "This is an important detail to remember",
    })
    let _ = todo_tool.call({
      "action": "update",
      "task_id": "1ea1417c",
      "priority": "low",
    })
    let result = todo_tool.call({ "action": "read" })
    @json.inspect(
      result
      .to_json()
      .transform(@json.Replacer::exclude(["created_at", "updated_at", "id"])),
      content=[
        "Ok",
        {
          "todos": [
            {
              "content": "Task with notes",
              "notes": "This is an important detail to remember",
              "priority": "Medium",
              "status": "Pending",
            },
            {
              "content": "Task without notes",
              "priority": "Low",
              "status": "Pending",
            },
          ],
        },
      ],
    )
    inspect(
      result,
      content=(
        #|=== Current Session Todo List ===
        #|
        #|1. ⏳ 🟡 [ac8a366d] Task with notes
        #|   └─ 📝 This is an important detail to remember
        #|2. ⏳ 🟢 [1ea1417c] Task without notes
        #|
        #|📊 Summary: Total: 2 | ⏳ Pending: 2
      ),
    )
  })
}

///|
async test "todo/read/all_completed" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let todo_tool = @todo_tools.new(todo_list)

    // Create and complete multiple tasks
    let _ = todo_tool.call({
      "action": "create",
      "content": (
        #|Completed task 1
        #|Completed task 2
        #|Completed task 3
      ),
      "priority": "high",
    })
    let _ = todo_tool.call({
      "action": "mark_completed",
      "task_id": "ac8a366d",
    })
    let _ = todo_tool.call({
      "action": "mark_completed",
      "task_id": "1ea1417c",
    })
    let _ = todo_tool.call({
      "action": "mark_completed",
      "task_id": "f378dd8d",
    })
    let result = todo_tool.call({ "action": "read" })
    @json.inspect(
      result
      .to_json()
      .transform(@json.Replacer::exclude(["created_at", "updated_at", "id"])),
      content=[
        "Ok",
        {
          "todos": [
            {
              "content": "Completed task 1",
              "priority": "High",
              "status": "Completed",
            },
            {
              "content": "Completed task 2",
              "priority": "High",
              "status": "Completed",
            },
            {
              "content": "Completed task 3",
              "priority": "High",
              "status": "Completed",
            },
          ],
        },
      ],
    )
    inspect(
      result,
      content=(
        #|=== Current Session Todo List ===
        #|
        #|1. ✅ 🔴 [ac8a366d] Completed task 1
        #|2. ✅ 🔴 [1ea1417c] Completed task 2
        #|3. ✅ 🔴 [f378dd8d] Completed task 3
        #|
        #|📊 Summary: Total: 3 | ✅ Completed: 3
      ),
    )
  })
}

///|
async test "todo/read/all_in_progress" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let todo_tool = @todo_tools.new(todo_list)

    // Create and mark all tasks as in progress
    let _ = todo_tool.call({
      "action": "create",
      "content": (
        #|In progress task 1
        #|In progress task 2
      ),
      "priority": "medium",
    })
    let _ = todo_tool.call({ "action": "mark_progress", "task_id": "ac8a366d" })
    let _ = todo_tool.call({ "action": "mark_progress", "task_id": "1ea1417c" })
    let result = todo_tool.call({ "action": "read" })
    @json.inspect(
      result
      .to_json()
      .transform(@json.Replacer::exclude(["created_at", "updated_at", "id"])),
      content=[
        "Ok",
        {
          "todos": [
            {
              "content": "In progress task 1",
              "priority": "Medium",
              "status": "InProgress",
            },
            {
              "content": "In progress task 2",
              "priority": "Medium",
              "status": "InProgress",
            },
          ],
        },
      ],
    )
    inspect(
      result,
      content=(
        #|=== Current Session Todo List ===
        #|
        #|1. 🔄 🟡 [ac8a366d] In progress task 1
        #|2. 🔄 🟡 [1ea1417c] In progress task 2
        #|
        #|📊 Summary: Total: 2 | 🔄 In Progress: 2
      ),
    )
  })
}

///|
async test "todo/read/complex_scenario" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let todo_tool = @todo_tools.new(todo_list)

    // Create a complex scenario with mixed priorities, statuses, and notes
    let _ = todo_tool.call({
      "action": "create",
      "content": (
        #|Critical bug fix
        #|Code review
        #|Update documentation
        #|Write unit tests
      ),
      "priority": "high",
    })

    // Update priorities and add notes
    let _ = todo_tool.call({
      "action": "update",
      "task_id": "ac8a366d",
      "notes": "Blocking production release",
    })
    let _ = todo_tool.call({
      "action": "update",
      "task_id": "1ea1417c",
      "priority": "medium",
    })
    let _ = todo_tool.call({
      "action": "update",
      "task_id": "f378dd8d",
      "priority": "low",
      "notes": "Add examples for new API",
    })

    // Update statuses
    let _ = todo_tool.call({ "action": "mark_progress", "task_id": "ac8a366d" })
    let _ = todo_tool.call({
      "action": "mark_completed",
      "task_id": "1ea1417c",
    })
    let result = todo_tool.call({ "action": "read" })
    @json.inspect(
      result
      .to_json()
      .transform(@json.Replacer::exclude(["created_at", "updated_at", "id"])),
      content=[
        "Ok",
        {
          "todos": [
            {
              "content": "Critical bug fix",
              "notes": "Blocking production release",
              "priority": "Medium",
              "status": "InProgress",
            },
            {
              "content": "Code review",
              "priority": "Medium",
              "status": "Completed",
            },
            {
              "content": "Update documentation",
              "notes": "Add examples for new API",
              "priority": "Low",
              "status": "Pending",
            },
            {
              "content": "Write unit tests",
              "priority": "High",
              "status": "Pending",
            },
          ],
        },
      ],
    )
    inspect(
      result,
      content=(
        #|=== Current Session Todo List ===
        #|
        #|1. 🔄 🟡 [ac8a366d] Critical bug fix
        #|   └─ 📝 Blocking production release
        #|2. ✅ 🟡 [1ea1417c] Code review
        #|3. ⏳ 🟢 [f378dd8d] Update documentation
        #|   └─ 📝 Add examples for new API
        #|4. ⏳ 🔴 [42858c8d] Write unit tests
        #|
        #|📊 Summary: Total: 4 | ✅ Completed: 1 | 🔄 In Progress: 1 | ⏳ Pending: 2
      ),
    )
  })
}

///|
async test "todo/read/updated_task_content" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let todo_tool = @todo_tools.new(todo_list)

    // Create a task
    let _ = todo_tool.call({
      "action": "create",
      "content": "Original task content",
      "priority": "medium",
    })

    // Update the task content
    let _ = todo_tool.call({
      "action": "update",
      "task_id": "ac8a366d",
      "content": "Updated task content",
      "priority": "high",
      "notes": "Added some context",
    })
    let result = todo_tool.call({ "action": "read" })
    @json.inspect(
      result
      .to_json()
      .transform(@json.Replacer::exclude(["created_at", "updated_at", "id"])),
      content=[
        "Ok",
        {
          "todos": [
            {
              "content": "Updated task content",
              "notes": "Added some context",
              "priority": "High",
              "status": "Pending",
            },
          ],
        },
      ],
    )
    inspect(
      result,
      content=(
        #|=== Current Session Todo List ===
        #|
        #|1. ⏳ 🔴 [ac8a366d] Updated task content
        #|   └─ 📝 Added some context
        #|
        #|📊 Summary: Total: 1 | ⏳ Pending: 1
      ),
    )
  })
}

///| Tests for todo_write

///|
async test "todo/create/plain" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/create/<task>" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/update" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({
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
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/mark_completed" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({
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
    let result = @todo_tools.new(todo_list).call({
      "action": "mark_completed",
      "task_id": "nonexistent",
    })
    @json.inspect(result, content=[
      "Error",
      ["ToolFailure", "Error: Task with ID 'nonexistent' not found."],
      "Error: Task with ID 'nonexistent' not found.",
    ])
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/mark_progress" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({
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
    let result = @todo_tools.new(todo_list).call({
      "action": "mark_progress",
      "task_id": "nonexistent",
    })
    @json.inspect(result, content=[
      "Error",
      ["ToolFailure", "Error: Task with ID 'nonexistent' not found."],
      "Error: Task with ID 'nonexistent' not found.",
    ])
    inspect(result, content="Error: Task with ID 'nonexistent' not found.")
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/add_task" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    // Create initial list
    let result = @todo_tools.new(todo_list).call({
      "action": "create",
      "content": "Initial task",
      "priority": "medium",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Add a new task
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/multiple_priority_levels" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({
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
    let result = @todo_tools.new(todo_list).call({
      "action": "update",
      "task_id": "1ea1417c",
      "priority": "medium",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/workflow_complete_cycle" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    // Create tasks
    let result = @todo_tools.new(todo_list).call({
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
    let result = @todo_tools.new(todo_list).call({
      "action": "mark_progress",
      "task_id": "ac8a366d",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Complete first task
    let result = @todo_tools.new(todo_list).call({
      "action": "mark_completed",
      "task_id": "ac8a366d",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Start second task
    let result = @todo_tools.new(todo_list).call({
      "action": "mark_progress",
      "task_id": "1ea1417c",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Complete second task
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/error_invalid_action" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/error_missing_content_for_create" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({ "action": "create" })
    @json.inspect(result, content=[
      "Error",
      ["ToolFailure", "Error: Content is required for creating todos."],
      "Error: Content is required for creating todos.",
    ])
    inspect(result, content="Error: Content is required for creating todos.")
  })
}

///|
async test "todo/error_missing_content_for_add_task" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({ "action": "add_task" })
    @json.inspect(result, content=[
      "Error",
      ["ToolFailure", "Error: Content is required for adding a task."],
      "Error: Content is required for adding a task.",
    ])
    inspect(result, content="Error: Content is required for adding a task.")
  })
}

///|
async test "todo/error_missing_task_id_for_update" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/error_invalid_priority" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/error_invalid_status" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/update_with_notes" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    // Create initial task
    let result = @todo_tools.new(todo_list).call({
      "action": "create",
      "content": "Implement feature X",
      "priority": "high",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Update with notes
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/update_content_only" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    // Create initial task
    let result = @todo_tools.new(todo_list).call({
      "action": "create",
      "content": "Original task description",
      "priority": "medium",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Update content only
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/add_task_with_in_progress_status" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    // Create initial list
    let result = @todo_tools.new(todo_list).call({
      "action": "create",
      "content": "First task",
      "priority": "medium",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Add a new task directly as in-progress
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/create_with_low_priority" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    let result = @todo_tools.new(todo_list).call({
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
async test "todo/mark_completed_then_reopen" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = new(clock=mock.clock, uuid=mock.uuid, cwd=mock.cwd.path())
    // Create task
    let result = @todo_tools.new(todo_list).call({
      "action": "create",
      "content": "Task that needs rework",
      "priority": "high",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Mark as completed
    let result = @todo_tools.new(todo_list).call({
      "action": "mark_completed",
      "task_id": "ac8a366d",
    })
    guard result is Ok(_) else { fail("Expected Ok result but got: \{result}") }
    // Reopen task by updating status back to pending
    let result = @todo_tools.new(todo_list).call({
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
