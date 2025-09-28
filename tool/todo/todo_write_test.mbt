///|
async test "todo_write/create/plain" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @async.with_task_group(group => {
    let cwd = @mock.directory("tool-todo_write")
    group.add_defer(() => cwd.close())
    let todo_list = @todo.list(rand~, cwd=cwd.path())
    let result = @todo.write.call(
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
      (@todo.write.render)(result),
      content=(
        #|✅ Operation completed: Created 2 new todo items
        #|
        #|📝 Newly created todos:
        #|  🔴 ⏳ [b773b606] Test todo item
        #|  🔴 ⏳ [8c2599d9] Another test item
        #|
        #|📊 Current summary: Total 2 items | Pending 2 | In Progress 0 | Completed 0
      ),
    )
  })
}

///|
async test "todo_write/create/<task>" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @async.with_task_group(group => {
    let cwd = @mock.directory("tool-todo_write")
    group.add_defer(() => cwd.close())
    let todo_list = @todo.list(rand~, cwd=cwd.path())
    let result = @todo.write.call(
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
      todo_list,
    )
    inspect(
      (@todo.write.render)(result),
      content=(
        #|✅ Operation completed: Created 7 new todo items
        #|
        #|📝 Newly created todos:
        #|  🟡 ⏳ [b773b606] Examine reference repository structure at .moonagent/repos/inih
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
async test "todo_write/update" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @async.with_task_group(group => {
    let cwd = @mock.directory("togol-todo_write")
    group.add_defer(() => cwd.close())
    let todo_list = @todo.list(rand~, cwd=cwd.path())
    let result = @todo.write.call(
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
      (@todo.write.render)(result),
      content=(
        #|✅ Operation completed: Created 2 new todo items
        #|
        #|📝 Newly created todos:
        #|  🟡 ⏳ [b773b606] First item
        #|  🟡 ⏳ [8c2599d9] Second item
        #|
        #|📊 Current summary: Total 2 items | Pending 2 | In Progress 0 | Completed 0
      ),
    )
    let result = @todo.write.call(
      {
        "action": "update",
        "task_id": "b773b606",
        "status": "in-progress",
        "priority": "high",
        "content": "Updated first item",
      },
      todo_list,
    )
    inspect(
      (@todo.write.render)(result),
      content=(
        #|✅ Operation completed: Updated task: Updated first item
        #|
        #|📝 Current todo list:
        #|  🔴 🔄 [b773b606] Updated first item
        #|  🟡 ⏳ [8c2599d9] Second item
        #|
        #|✨ Updated items:
        #|  🔴 🔄 [b773b606] Updated first item
        #|
        #|📊 Current summary: Total 2 items | Pending 1 | In Progress 1 | Completed 0
      ),
    )
  })
}

///|
async test "todo_write/mark_completed" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @async.with_task_group(group => {
    let cwd = @mock.directory("tool-todo_write")
    group.add_defer(() => cwd.close())
    let todo_list = @todo.list(rand~, cwd=cwd.path())
    let result = @todo.write.call(
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
    fn drop_time(json : Json) -> Json {
      if json is Object(obj) {
        let obj = obj.map((key, value) => if key == "created_at" ||
          key == "updated_at" {
          String("...")
        } else {
          drop_time(value)
        })
        Json::object(obj)
      } else if json is Array(arr) {
        Json::array(arr.map(item => drop_time(item)))
      } else {
        json
      }
    }

    @json.inspect(drop_time(result.output), content={
      "todos": [
        {
          "content": "First item",
          "created_at": "...",
          "id": "b773b606",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "...",
        },
        {
          "content": "Second item",
          "created_at": "...",
          "id": "8c2599d9",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "...",
        },
      ],
      "message": "Created 2 new todo items",
      "updated_todos": [
        {
          "content": "First item",
          "created_at": "...",
          "id": "b773b606",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "...",
        },
        {
          "content": "Second item",
          "created_at": "...",
          "id": "8c2599d9",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "...",
        },
      ],
      "is_new_creation": true,
    })
    inspect(
      (@todo.write.render)(result),
      content=(
        #|✅ Operation completed: Created 2 new todo items
        #|
        #|📝 Newly created todos:
        #|  🟡 ⏳ [b773b606] First item
        #|  🟡 ⏳ [8c2599d9] Second item
        #|
        #|📊 Current summary: Total 2 items | Pending 2 | In Progress 0 | Completed 0
      ),
    )
    let result = @todo.write.call(
      { "action": "mark_completed", "task_id": "b773b606" },
      todo_list,
    )
    @json.inspect(drop_time(result.output), content={
      "todos": [
        {
          "content": "First item",
          "created_at": "...",
          "id": "b773b606",
          "priority": "Medium",
          "status": "Completed",
          "updated_at": "...",
        },
        {
          "content": "Second item",
          "created_at": "...",
          "id": "8c2599d9",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "...",
        },
      ],
      "message": "Marked task as completed: First item",
      "updated_todos": [
        {
          "content": "First item",
          "created_at": "...",
          "id": "b773b606",
          "priority": "Medium",
          "status": "Completed",
          "updated_at": "...",
        },
      ],
      "is_new_creation": false,
    })
    inspect(
      (@todo.write.render)(result),
      content=(
        #|✅ Operation completed: Marked task as completed: First item
        #|
        #|📝 Current todo list:
        #|  🟡 ✅ [b773b606] First item
        #|  🟡 ⏳ [8c2599d9] Second item
        #|
        #|✨ Updated items:
        #|  🟡 ✅ [b773b606] First item
        #|
        #|📊 Current summary: Total 2 items | Pending 1 | In Progress 0 | Completed 1
      ),
    )
  })
}
