///|
async test "todo_write/create/plain" (t : @test.T) {
  @mock.run(t, taco => {
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
    inspect(
      result.output,
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
  @mock.run(t, taco => {
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
    inspect(
      result.output,
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
  @mock.run(t, taco => {
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
    inspect(
      result.output,
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
      {
        "action": "update",
        "task_id": "ac8a366d",
        "status": "in-progress",
        "priority": "high",
        "content": "Updated first item",
      },
      todo_list,
    )
    inspect(
      result.output,
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
  @mock.run(t, taco => {
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
    inspect(
      result.output,
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
    inspect(
      result.output,
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
  @mock.run(t, taco => {
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
      "output": "✅ Operation completed: Created 2 new todo items\n\n📝 Newly created todos:\n  🟡 ⏳ [ac8a366d] First item\n  🟡 ⏳ [1ea1417c] Second item\n\n📊 Current summary: Total 2 items | Pending 2 | In Progress 0 | Completed 0",
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
      result.output,
      content="Error: Task with ID 'nonexistent' not found.",
    )
    let result = @todo_write.todo_write.call(
      { "action": "mark_progress", "task_id": "ac8a366d" },
      todo_list,
    )
    @json.inspect(result, content={
      "output": "✅ Operation completed: Marked task as in progress: First item\n\n📝 Current todo list:\n  🟡 🔄 [ac8a366d] First item\n  🟡 ⏳ [1ea1417c] Second item\n\n✨ Updated items:\n  🟡 🔄 [ac8a366d] First item\n\n📊 Current summary: Total 2 items | Pending 1 | In Progress 1 | Completed 0",
    })
    inspect(
      result.output,
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
