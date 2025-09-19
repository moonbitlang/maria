///|
test "todo_write/create/plain" {
  @rand.seed()
  @async.with_event_loop(group => {
    let cwd = @mock.directory("tool-todo_write")
    group.add_defer(() => cwd.close())
    let result = @todo_write.todo_write.call(
      {
        "action": "create",
        "content": (
          #|Test todo item
          #|Another test item
        ),
        "priority": "high",
      },
      @tool.context(model=@mock.model(), cwd=cwd.path()),
    )
    inspect(
      result.output,
      content=(
        #|✅ Operation completed: Created 2 new todo items
        #|
        #|📝 Newly created todos:
        #|  🔴 ⏳ [a516463d] Test todo item
        #|  🔴 ⏳ [7c288d41] Another test item
        #|
        #|📊 Current summary: Total 2 items | Pending 2 | In Progress 0 | Completed 0
      ),
    )
  })
}

///|
test "todo_write/create/<task>" {
  @rand.seed()
  @async.with_event_loop(group => {
    let cwd = @mock.directory("tool-todo_write")
    group.add_defer(() => cwd.close())
    let result = @todo_write.todo_write.call(
      {
        "action": "create",
        "content": (
          #|<task>Examine reference repository structure at .moonagent/repos/inih</task>
          #|<task>Examine current MoonBit project structure</task>
          #|<task>Analyze source files in inih repository</task>
          #|<task>Plan migration strategy preserving original structure</task>
          #|<task>Translate C/C++ files to MoonBit file-by-file</task>
          #|<task>Create appropriate MoonBit module structure</task>
          #|<task>Test migrated functionality</task>
        ),
      },
      @tool.context(model=@mock.model(), cwd=cwd.path()),
    )
    inspect(
      result.output,
      content=(
        #|✅ Operation completed: Created 7 new todo items
        #|
        #|📝 Newly created todos:
        #|  🟡 ⏳ [b773b606] Examine reference repository structure at /Users/haoxiang/Workspace/moonbit/maria/.moonagent/repos/inih
        #|  🟡 ⏳ [8c2599d9] Examine current MoonBit project structure
        #|  🟡 ⏳ [cfaa9ee0] Analyze source files in inih repository
        #|  🟡 ⏳ [3c82d271] Plan migration strategy preserving original structure
        #|  🟡 ⏳ [df79bb61] Translate C/C++ files to MoonBit file-by-file
        #|  🟡 ⏳ [eef0d14e] Create appropriate MoonBit module structure
        #|  🟡 ⏳ [d9e52b59] Test migrated functionality
        #|
        #|📊 Current summary: Total 7 items | Pending 7 | In Progress 0 | Completed 0
      ),
    )
  })
}

///|
test "todo_write/update" {
  @rand.seed()
  @async.with_event_loop(group => {
    let cwd = @mock.directory("togol-todo_write")
    group.add_defer(() => cwd.close())
    let manager = @todo.Manager::new(cwd=cwd.path())
    manager.load()
    let todo1 = manager.add_task("First item", priority=Medium)
    let _ = manager.add_task("Second item", priority=Low)
    manager.save()
    let result = @todo_write.todo_write.call(
      {
        "action": "update",
        "task_id": todo1.id,
        "status": "in-progress",
        "priority": "high",
        "content": "Updated first item",
      },
      @tool.context(model=@mock.model(), cwd=cwd.path()),
    )
    inspect(
      result.output,
      content=(
        #|✅ Operation completed: Updated task: Updated first item
        #|
        #|📝 Current todo list:
        #|  🔴 🔄 [a516463d] Updated first item
        #|  🟢 ⏳ [7c288d41] Second item
        #|
        #|✨ Updated items:
        #|  🔴 🔄 [a516463d] Updated first item
        #|
        #|📊 Current summary: Total 2 items | Pending 1 | In Progress 1 | Completed 0
      ),
    )
  })
}

///|
test "todo_write/mark_completed" {
  @rand.seed()
  @async.with_event_loop(group => {
    let cwd = @mock.directory("tool-todo_write")
    group.add_defer(() => cwd.close())
    let manager = @todo.Manager::new(cwd=cwd.path())
    manager.load()
    let todo1 = manager.add_task("First item", priority=Medium)
    let _ = manager.add_task("Second item", priority=Low)
    manager.save()
    let result = @todo_write.todo_write.call(
      { "action": "mark_completed", "task_id": todo1.id },
      @tool.context(model=@mock.model(), cwd=cwd.path()),
    )
    inspect(
      result.output,
      content=(
        #|✅ Operation completed: Marked task as completed: First item
        #|
        #|📝 Current todo list:
        #|  🟡 ✅ [b773b606] First item
        #|  🟢 ⏳ [8c2599d9] Second item
        #|
        #|✨ Updated items:
        #|  🟡 ✅ [b773b606] First item
        #|
        #|📊 Current summary: Total 2 items | Pending 1 | In Progress 0 | Completed 1
      ),
    )
  })
}
