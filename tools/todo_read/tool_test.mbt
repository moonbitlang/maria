///|
async test "todo_read/empty" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let read_tool = @todo_read.new(todo_list)
    let result = read_tool.call({})
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
async test "todo_read/single_task" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let read_tool = @todo_read.new(todo_list)
    let write_tool = @todo_write.new(todo_list)
    let _ = write_tool.call({
      "action": "create",
      "content": "A sample task",
      "priority": "medium",
    })
    let result = read_tool.call({})
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
async test "todo_read/multiple_tasks_mixed_status" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let read_tool = @todo_read.new(todo_list)
    let write_tool = @todo_write.new(todo_list)

    // Create multiple tasks
    let _ = write_tool.call({
      "action": "create",
      "content": (
        #|Task one
        #|Task two
        #|Task three
      ),
      "priority": "high",
    })

    // Mark first task as in-progress
    let _ = write_tool.call({ "action": "mark_progress", "task_id": "ac8a366d" })

    // Mark second task as completed
    let _ = write_tool.call({
      "action": "mark_completed",
      "task_id": "1ea1417c",
    })
    let result = read_tool.call({})
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
async test "todo_read/different_priorities" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let read_tool = @todo_read.new(todo_list)
    let write_tool = @todo_write.new(todo_list)

    // Create tasks with different priorities
    let _ = write_tool.call({
      "action": "create",
      "content": (
        #|High priority task
        #|Medium priority task
        #|Low priority task
      ),
      "priority": "high",
    })

    // Update priorities individually
    let _ = write_tool.call({
      "action": "update",
      "task_id": "1ea1417c",
      "priority": "medium",
    })
    let _ = write_tool.call({
      "action": "update",
      "task_id": "f378dd8d",
      "priority": "low",
    })
    let result = read_tool.call({})
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
async test "todo_read/with_notes" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let read_tool = @todo_read.new(todo_list)
    let write_tool = @todo_write.new(todo_list)

    // Create tasks
    let _ = write_tool.call({
      "action": "create",
      "content": (
        #|Task with notes
        #|Task without notes
      ),
      "priority": "medium",
    })

    // Add notes to first task and change second priority
    let _ = write_tool.call({
      "action": "update",
      "task_id": "ac8a366d",
      "notes": "This is an important detail to remember",
    })
    let _ = write_tool.call({
      "action": "update",
      "task_id": "1ea1417c",
      "priority": "low",
    })
    let result = read_tool.call({})
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
async test "todo_read/all_completed" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let read_tool = @todo_read.new(todo_list)
    let write_tool = @todo_write.new(todo_list)

    // Create and complete multiple tasks
    let _ = write_tool.call({
      "action": "create",
      "content": (
        #|Completed task 1
        #|Completed task 2
        #|Completed task 3
      ),
      "priority": "high",
    })
    let _ = write_tool.call({
      "action": "mark_completed",
      "task_id": "ac8a366d",
    })
    let _ = write_tool.call({
      "action": "mark_completed",
      "task_id": "1ea1417c",
    })
    let _ = write_tool.call({
      "action": "mark_completed",
      "task_id": "f378dd8d",
    })
    let result = read_tool.call({})
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
async test "todo_read/all_in_progress" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let read_tool = @todo_read.new(todo_list)
    let write_tool = @todo_write.new(todo_list)

    // Create and mark all tasks as in progress
    let _ = write_tool.call({
      "action": "create",
      "content": (
        #|In progress task 1
        #|In progress task 2
      ),
      "priority": "medium",
    })
    let _ = write_tool.call({ "action": "mark_progress", "task_id": "ac8a366d" })
    let _ = write_tool.call({ "action": "mark_progress", "task_id": "1ea1417c" })
    let result = read_tool.call({})
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
async test "todo_read/complex_scenario" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let read_tool = @todo_read.new(todo_list)
    let write_tool = @todo_write.new(todo_list)

    // Create a complex scenario with mixed priorities, statuses, and notes
    let _ = write_tool.call({
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
    let _ = write_tool.call({
      "action": "update",
      "task_id": "ac8a366d",
      "notes": "Blocking production release",
    })
    let _ = write_tool.call({
      "action": "update",
      "task_id": "1ea1417c",
      "priority": "medium",
    })
    let _ = write_tool.call({
      "action": "update",
      "task_id": "f378dd8d",
      "priority": "low",
      "notes": "Add examples for new API",
    })

    // Update statuses
    let _ = write_tool.call({ "action": "mark_progress", "task_id": "ac8a366d" })
    let _ = write_tool.call({
      "action": "mark_completed",
      "task_id": "1ea1417c",
    })
    let result = read_tool.call({})
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
async test "todo_read/updated_task_content" (t : @test.Test) {
  @mock.run(t, mock => {
    let todo_list = @todo.new(
      clock=mock.clock,
      uuid=mock.uuid,
      cwd=mock.cwd.path(),
    )
    let read_tool = @todo_read.new(todo_list)
    let write_tool = @todo_write.new(todo_list)

    // Create a task
    let _ = write_tool.call({
      "action": "create",
      "content": "Original task content",
      "priority": "medium",
    })

    // Update the task content
    let _ = write_tool.call({
      "action": "update",
      "task_id": "ac8a366d",
      "content": "Updated task content",
      "priority": "high",
      "notes": "Added some context",
    })
    let result = read_tool.call({})
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
