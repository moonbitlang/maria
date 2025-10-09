///|
fn[T : ToJson] drop_id(json : T) -> Json {
  let json = json.to_json()
  if json is Object(obj) {
    let obj = obj.map((key, value) => if key == "id" {
      String("...")
    } else {
      drop_id(value)
    })
    Json::object(obj)
  } else if json is Array(arr) {
    Json::array(arr.map(item => drop_id(item)))
  } else {
    json
  }
}

///|
fn[T : ToJson] drop_time(json : T) -> Json {
  let json = json.to_json()
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

///|
fn[T : ToJson] drop_id_and_time(json : T) -> Json {
  drop_id(drop_time(json))
}

///|
async test "todo_write/create/plain" {
  @async.with_task_group(group => {
    let cwd = @mock.directory("tool-todo_write")
    group.add_defer(() => cwd.close())
    let todo_list = @todo.list(cwd=cwd.path())
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
    @json.inspect(drop_id_and_time(result), content={
      "output": {
        "todos": [
          {
            "content": "Test todo item",
            "created_at": "...",
            "id": "...",
            "priority": "High",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Another test item",
            "created_at": "...",
            "id": "...",
            "priority": "High",
            "status": "Pending",
            "updated_at": "...",
          },
        ],
        "message": "Created 2 new todo items",
        "updated_todos": [
          {
            "content": "Test todo item",
            "created_at": "...",
            "id": "...",
            "priority": "High",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Another test item",
            "created_at": "...",
            "id": "...",
            "priority": "High",
            "status": "Pending",
            "updated_at": "...",
          },
        ],
        "is_new_creation": true,
      },
    })
  })
}

///|
async test "todo_write/create/<task>" {
  @async.with_task_group(group => {
    let cwd = @mock.directory("tool-todo_write")
    group.add_defer(() => cwd.close())
    let todo_list = @todo.list(cwd=cwd.path())
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
      todo_list,
    )
    @json.inspect(drop_id_and_time(result), content={
      "output": {
        "todos": [
          {
            "content": "Examine reference repository structure at .moonagent/repos/inih",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Examine current MoonBit project structure",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Analyze source files in inih repository",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Plan migration strategy preserving original structure",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Translate C/C++ files to MoonBit file-by-file",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Create appropriate MoonBit module structure",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Test migrated functionality",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
        ],
        "message": "Created 7 new todo items",
        "updated_todos": [
          {
            "content": "Examine reference repository structure at .moonagent/repos/inih",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Examine current MoonBit project structure",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Analyze source files in inih repository",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Plan migration strategy preserving original structure",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Translate C/C++ files to MoonBit file-by-file",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Create appropriate MoonBit module structure",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Test migrated functionality",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
        ],
        "is_new_creation": true,
      },
    })
  })
}

///|
async test "todo_write/update" {
  @async.with_task_group(group => {
    let cwd = @mock.directory("todo-todo_write")
    group.add_defer(() => cwd.close())
    let todo_list = @todo.list(cwd=cwd.path())
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
    @json.inspect(drop_id_and_time(result), content={
      "output": {
        "todos": [
          {
            "content": "First item",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Second item",
            "created_at": "...",
            "id": "...",
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
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Second item",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
        ],
        "is_new_creation": true,
      },
    })
    let result = @todo_write.todo_write.call(
      {
        "action": "update",
        "task_id": "b773b606",
        "status": "in-progress",
        "priority": "high",
        "content": "Updated first item",
      },
      todo_list,
    )
    @json.inspect(drop_id_and_time(result), content={
      "output": "Error: Task with ID 'b773b606' not found.",
      "error": "moonbitlang/maria/tool.Failure.Failure",
    })
  })
}

///|
async test "todo_write/mark_completed" {
  @async.with_task_group(group => {
    let cwd = @mock.directory("tool-todo_write")
    group.add_defer(() => cwd.close())
    let todo_list = @todo.list(cwd=cwd.path())
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
    @json.inspect(drop_id_and_time(result.output), content={
      "todos": [
        {
          "content": "First item",
          "created_at": "...",
          "id": "...",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "...",
        },
        {
          "content": "Second item",
          "created_at": "...",
          "id": "...",
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
          "id": "...",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "...",
        },
        {
          "content": "Second item",
          "created_at": "...",
          "id": "...",
          "priority": "Medium",
          "status": "Pending",
          "updated_at": "...",
        },
      ],
      "is_new_creation": true,
    })
    @json.inspect(drop_id_and_time(result), content={
      "output": {
        "todos": [
          {
            "content": "First item",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Second item",
            "created_at": "...",
            "id": "...",
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
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
          {
            "content": "Second item",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
        ],
        "is_new_creation": true,
      },
    })
    let result = @todo_write.todo_write.call(
      { "action": "mark_completed", "task_id": "b773b606" },
      todo_list,
    )
    @json.inspect(
      drop_time(result.output),
      content="Error: Task with ID 'b773b606' not found.",
    )
    @json.inspect(drop_id_and_time(result), content={
      "output": "Error: Task with ID 'b773b606' not found.",
      "error": "moonbitlang/maria/tool.Failure.Failure",
    })
  })
}
