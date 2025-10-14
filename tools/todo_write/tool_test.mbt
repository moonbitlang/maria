///|
async test "todo_write/create/plain" (t : @test.T) {
  @taco.run(t, taco => {
    let todo_list = @todo.list(
      clock=taco.clock,
      uuid=taco.uuid,
      cwd=taco.cwd.path(),
    )
    let result = @todo_write.todo_write.call(
      {
        "action": "create",
        "content": (
          #|Test todo item
          #|Another test item
        ),
        "priority": "high",
      },
      todo_list,
    )
    @json.inspect(result, content={
      "output": {
        "todos": [
          {
            "content": "Test todo item",
            "created_at": "1970-01-01T00:00:00.003Z",
            "id": "ac8a366d",
            "priority": "High",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.003Z",
          },
          {
            "content": "Another test item",
            "created_at": "1970-01-01T00:00:00.004Z",
            "id": "1ea1417c",
            "priority": "High",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.004Z",
          },
        ],
        "message": "Created 2 new todo items",
        "updated_todos": [
          {
            "content": "Test todo item",
            "created_at": "1970-01-01T00:00:00.003Z",
            "id": "ac8a366d",
            "priority": "High",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.003Z",
          },
          {
            "content": "Another test item",
            "created_at": "1970-01-01T00:00:00.004Z",
            "id": "1ea1417c",
            "priority": "High",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.004Z",
          },
        ],
        "is_new_creation": true,
      },
    })
    inspect(
      (@todo_write.todo_write.render)(result),
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
async test "todo_write/create/<task>" (t : @test.T) {
  @taco.run(t, taco => {
    let todo_list = @todo.list(
      clock=taco.clock,
      uuid=taco.uuid,
      cwd=taco.cwd.path(),
    )
    let result = @todo_write.todo_write.call(
      {
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
      },
      todo_list,
    )
    @json.inspect(result, content={
      "output": {
        "todos": [
          {
            "content": "Examine reference repository structure at .moonagent/repos/ini",
            "created_at": "1970-01-01T00:00:00.003Z",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.003Z",
          },
          {
            "content": "Examine current MoonBit project structure",
            "created_at": "1970-01-01T00:00:00.004Z",
            "id": "1ea1417c",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.004Z",
          },
          {
            "content": "Analyze source files in ini repository",
            "created_at": "1970-01-01T00:00:00.005Z",
            "id": "f378dd8d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.005Z",
          },
          {
            "content": "Plan migration strategy preserving original structure",
            "created_at": "1970-01-01T00:00:00.006Z",
            "id": "42858c8d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.006Z",
          },
          {
            "content": "Translate C/C++ files to MoonBit file-by-file",
            "created_at": "1970-01-01T00:00:00.007Z",
            "id": "1258fdc0",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.007Z",
          },
          {
            "content": "Create appropriate MoonBit module structure",
            "created_at": "1970-01-01T00:00:00.008Z",
            "id": "aaa2f959",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.008Z",
          },
          {
            "content": "Test migrated functionality",
            "created_at": "1970-01-01T00:00:00.009Z",
            "id": "8f0ff2dc",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.009Z",
          },
        ],
        "message": "Created 7 new todo items",
        "updated_todos": [
          {
            "content": "Examine reference repository structure at .moonagent/repos/ini",
            "created_at": "1970-01-01T00:00:00.003Z",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.003Z",
          },
          {
            "content": "Examine current MoonBit project structure",
            "created_at": "1970-01-01T00:00:00.004Z",
            "id": "1ea1417c",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.004Z",
          },
          {
            "content": "Analyze source files in ini repository",
            "created_at": "1970-01-01T00:00:00.005Z",
            "id": "f378dd8d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.005Z",
          },
          {
            "content": "Plan migration strategy preserving original structure",
            "created_at": "1970-01-01T00:00:00.006Z",
            "id": "42858c8d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.006Z",
          },
          {
            "content": "Translate C/C++ files to MoonBit file-by-file",
            "created_at": "1970-01-01T00:00:00.007Z",
            "id": "1258fdc0",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.007Z",
          },
          {
            "content": "Create appropriate MoonBit module structure",
            "created_at": "1970-01-01T00:00:00.008Z",
            "id": "aaa2f959",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.008Z",
          },
          {
            "content": "Test migrated functionality",
            "created_at": "1970-01-01T00:00:00.009Z",
            "id": "8f0ff2dc",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.009Z",
          },
        ],
        "is_new_creation": true,
      },
    })
    inspect(
      (@todo_write.todo_write.render)(result),
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
async test "todo_write/update" (t : @test.T) {
  @taco.run(t, taco => {
    let todo_list = @todo.list(
      clock=taco.clock,
      uuid=taco.uuid,
      cwd=taco.cwd.path(),
    )
    let result = @todo_write.todo_write.call(
      {
        "action": "create",
        "content": (
          #|First item
          #|Second item
        ),
        "priority": "medium",
      },
      todo_list,
    )
    @json.inspect(result, content={
      "output": {
        "todos": [
          {
            "content": "First item",
            "created_at": "1970-01-01T00:00:00.003Z",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.003Z",
          },
          {
            "content": "Second item",
            "created_at": "1970-01-01T00:00:00.004Z",
            "id": "1ea1417c",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.004Z",
          },
        ],
        "message": "Created 2 new todo items",
        "updated_todos": [
          {
            "content": "First item",
            "created_at": "1970-01-01T00:00:00.003Z",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.003Z",
          },
          {
            "content": "Second item",
            "created_at": "1970-01-01T00:00:00.004Z",
            "id": "1ea1417c",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.004Z",
          },
        ],
        "is_new_creation": true,
      },
    })
    let result = @todo_write.todo_write.call(
      {
        "action": "update",
        "task_id": "ac8a366d",
        "status": "in-progress",
        "priority": "high",
        "content": "Updated first item",
      },
      todo_list,
    )
    @json.inspect(result, content={
      "output": {
        "todos": [
          {
            "content": "Updated first item",
            "created_at": "1970-01-01T00:00:00.003Z",
            "id": "ac8a366d",
            "priority": "High",
            "status": "InProgress",
            "updated_at": "1970-01-01T00:00:00.006Z",
          },
          {
            "content": "Second item",
            "created_at": "1970-01-01T00:00:00.004Z",
            "id": "1ea1417c",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.004Z",
          },
        ],
        "message": "Updated task: Updated first item",
        "updated_todos": [
          {
            "content": "Updated first item",
            "created_at": "1970-01-01T00:00:00.003Z",
            "id": "ac8a366d",
            "priority": "High",
            "status": "InProgress",
            "updated_at": "1970-01-01T00:00:00.006Z",
          },
        ],
        "is_new_creation": false,
      },
    })
    inspect(
      (@todo_write.todo_write.render)(result),
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
async test "todo_write/mark_completed" (t : @test.T) {
  @taco.run(t, taco => {
    let todo_list = @todo.list(
      clock=taco.clock,
      uuid=taco.uuid,
      cwd=taco.cwd.path(),
    )
    let result = @todo_write.todo_write.call(
      {
        "action": "create",
        "content": (
          #|First item
          #|Second item
        ),
        "priority": "medium",
      },
      todo_list,
    )
    @json.inspect(result.output, content={
      "todos": [
        {
          "content": "First item",
          "created_at": "1970-01-01T00:00:00.003Z",
          "id": "ac8a366d",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "1970-01-01T00:00:00.003Z",
        },
        {
          "content": "Second item",
          "created_at": "1970-01-01T00:00:00.004Z",
          "id": "1ea1417c",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "1970-01-01T00:00:00.004Z",
        },
      ],
      "message": "Created 2 new todo items",
      "updated_todos": [
        {
          "content": "First item",
          "created_at": "1970-01-01T00:00:00.003Z",
          "id": "ac8a366d",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "1970-01-01T00:00:00.003Z",
        },
        {
          "content": "Second item",
          "created_at": "1970-01-01T00:00:00.004Z",
          "id": "1ea1417c",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "1970-01-01T00:00:00.004Z",
        },
      ],
      "is_new_creation": true,
    })
    inspect(
      (@todo_write.todo_write.render)(result),
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
    let result = @todo_write.todo_write.call(
      { "action": "mark_completed", "task_id": "nonexistent" },
      todo_list,
    )
    @json.inspect(result, content={
      "output": "Error: Task with ID 'nonexistent' not found.",
      "error": ["Failure", "Error: Task with ID 'nonexistent' not found."],
    })
    let result = @todo_write.todo_write.call(
      { "action": "mark_completed", "task_id": "ac8a366d" },
      todo_list,
    )
    @json.inspect(result.output, content={
      "todos": [
        {
          "content": "First item",
          "created_at": "1970-01-01T00:00:00.003Z",
          "id": "ac8a366d",
          "priority": "Medium",
          "status": "Completed",
          "updated_at": "1970-01-01T00:00:00.006Z",
        },
        {
          "content": "Second item",
          "created_at": "1970-01-01T00:00:00.004Z",
          "id": "1ea1417c",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "1970-01-01T00:00:00.004Z",
        },
      ],
      "message": "Marked task as completed: First item",
      "updated_todos": [
        {
          "content": "First item",
          "created_at": "1970-01-01T00:00:00.003Z",
          "id": "ac8a366d",
          "priority": "Medium",
          "status": "Completed",
          "updated_at": "1970-01-01T00:00:00.006Z",
        },
      ],
      "is_new_creation": false,
    })
    inspect(
      (@todo_write.todo_write.render)(result),
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
async test "todo_write/mark_progress" (t : @test.T) {
  @taco.run(t, taco => {
    let todo_list = @todo.list(
      clock=taco.clock,
      uuid=taco.uuid,
      cwd=taco.cwd.path(),
    )
    let result = @todo_write.todo_write.call(
      {
        "action": "create",
        "content": (
          #|First item
          #|Second item
        ),
        "priority": "medium",
      },
      todo_list,
    )
    @json.inspect(result, content={
      "output": {
        "todos": [
          {
            "content": "First item",
            "created_at": "1970-01-01T00:00:00.003Z",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.003Z",
          },
          {
            "content": "Second item",
            "created_at": "1970-01-01T00:00:00.004Z",
            "id": "1ea1417c",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.004Z",
          },
        ],
        "message": "Created 2 new todo items",
        "updated_todos": [
          {
            "content": "First item",
            "created_at": "1970-01-01T00:00:00.003Z",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.003Z",
          },
          {
            "content": "Second item",
            "created_at": "1970-01-01T00:00:00.004Z",
            "id": "1ea1417c",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.004Z",
          },
        ],
        "is_new_creation": true,
      },
    })
    let result = @todo_write.todo_write.call(
      { "action": "mark_progress", "task_id": "nonexistent" },
      todo_list,
    )
    @json.inspect(result, content={
      "output": "Error: Task with ID 'nonexistent' not found.",
      "error": ["Failure", "Error: Task with ID 'nonexistent' not found."],
    })
    inspect(
      (@todo_write.todo_write.render)(result),
      content="Error: Unexpected output format",
    )
    let result = @todo_write.todo_write.call(
      { "action": "mark_progress", "task_id": "ac8a366d" },
      todo_list,
    )
    @json.inspect(result, content={
      "output": {
        "todos": [
          {
            "content": "First item",
            "created_at": "1970-01-01T00:00:00.003Z",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "InProgress",
            "updated_at": "1970-01-01T00:00:00.006Z",
          },
          {
            "content": "Second item",
            "created_at": "1970-01-01T00:00:00.004Z",
            "id": "1ea1417c",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "1970-01-01T00:00:00.004Z",
          },
        ],
        "message": "Marked task as in progress: First item",
        "updated_todos": [
          {
            "content": "First item",
            "created_at": "1970-01-01T00:00:00.003Z",
            "id": "ac8a366d",
            "priority": "Medium",
            "status": "InProgress",
            "updated_at": "1970-01-01T00:00:00.006Z",
          },
        ],
        "is_new_creation": false,
      },
    })
    inspect(
      (@todo_write.todo_write.render)(result),
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
