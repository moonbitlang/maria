///| Tests for parse_todo_args

///|
test "parse_todo_args/read_action" {
  let args : Json = { "action": "read" }
  let result = parse_todo_args(args)
  @json.inspect(result, content={
    "action": "Read",
    "priority": "Medium",
    "status": "Pending",
  })
}

///|
test "parse_todo_args/create_action_with_all_params" {
  let args : Json = {
    "action": "create",
    "content": "Test task",
    "priority": "high",
    "status": "pending",
    "notes": "Some notes",
  }
  let result = parse_todo_args(args)
  @json.inspect(result, content={
    "action": "Create",
    "content": "Test task",
    "priority": "High",
    "status": "Pending",
    "notes": "Some notes",
  })
}

///|
test "parse_todo_args/add_task_action" {
  let args : Json = { "action": "add_task", "content": "New task" }
  let result = parse_todo_args(args)
  @json.inspect(result, content={
    "action": "AddTask",
    "content": "New task",
    "priority": "Medium",
    "status": "Pending",
  })
}

///|
test "parse_todo_args/update_action_with_task_id" {
  let args : Json = {
    "action": "update",
    "task_id": "abc123",
    "content": "Updated content",
    "priority": "low",
  }
  let result = parse_todo_args(args)
  @json.inspect(result, content={
    "action": "Update",
    "content": "Updated content",
    "task_id": "abc123",
    "priority": "Low",
    "status": "Pending",
  })
}

///|
test "parse_todo_args/mark_progress_action" {
  let args : Json = { "action": "mark_progress", "task_id": "task-1" }
  let result = parse_todo_args(args)
  @json.inspect(result, content={
    "action": "MarkProgress",
    "task_id": "task-1",
    "priority": "Medium",
    "status": "Pending",
  })
}

///|
test "parse_todo_args/mark_completed_action" {
  let args : Json = { "action": "mark_completed", "task_id": "task-2" }
  let result = parse_todo_args(args)
  @json.inspect(result, content={
    "action": "MarkCompleted",
    "task_id": "task-2",
    "priority": "Medium",
    "status": "Pending",
  })
}

///|
test "parse_todo_args/case_insensitive_action" {
  let args : Json = { "action": "CREATE", "content": "Task" }
  let result = parse_todo_args(args)
  @json.inspect(result, content={
    "action": "Create",
    "content": "Task",
    "priority": "Medium",
    "status": "Pending",
  })
}

///|
test "parse_todo_args/status_in_progress_hyphen" {
  let args : Json = {
    "action": "add_task",
    "content": "Task",
    "status": "in-progress",
  }
  let result = parse_todo_args(args)
  @json.inspect(result, content={
    "action": "AddTask",
    "content": "Task",
    "priority": "Medium",
    "status": "InProgress",
  })
}

///|
test "parse_todo_args/status_in_progress_underscore" {
  let args : Json = {
    "action": "add_task",
    "content": "Task",
    "status": "in_progress",
  }
  let result = parse_todo_args(args)
  @json.inspect(result, content={
    "action": "AddTask",
    "content": "Task",
    "priority": "Medium",
    "status": "InProgress",
  })
}

///|
test "parse_todo_args/status_completed" {
  let args : Json = {
    "action": "add_task",
    "content": "Task",
    "status": "completed",
  }
  let result = parse_todo_args(args)
  @json.inspect(result, content={
    "action": "AddTask",
    "content": "Task",
    "priority": "Medium",
    "status": "Completed",
  })
}

///|
test "parse_todo_args/priority_medium" {
  let args : Json = {
    "action": "create",
    "content": "Task",
    "priority": "medium",
  }
  let result = parse_todo_args(args)
  @json.inspect(result, content={
    "action": "Create",
    "content": "Task",
    "priority": "Medium",
    "status": "Pending",
  })
}

///|
test "parse_todo_args/error_missing_action" {
  let args : Json = { "content": "Test task" }
  let result : Result[TodoArgs, TodoArgsError] = Ok(parse_todo_args(args)) catch {
    e => Err(e)
  }
  inspect(
    result,
    content="Err(TodoArgsError(\"Error: 'action' parameter is required\"))",
  )
}

///|
test "parse_todo_args/error_invalid_action" {
  let args : Json = { "action": "invalid" }
  let result : Result[TodoArgs, TodoArgsError] = Ok(parse_todo_args(args)) catch {
    e => Err(e)
  }
  inspect(
    result,
    content="Err(TodoArgsError(\"Error: Invalid action 'invalid'. Supported actions: read, create, add_task, update, mark_progress, mark_completed.\"))",
  )
}

///|
test "parse_todo_args/error_invalid_priority" {
  let args : Json = {
    "action": "create",
    "content": "Task",
    "priority": "urgent",
  }
  let result : Result[TodoArgs, TodoArgsError] = Ok(parse_todo_args(args)) catch {
    e => Err(e)
  }
  inspect(
    result,
    content="Err(TodoArgsError(\"Error: Invalid priority 'String(\\\"urgent\\\")'. Must be 'high', 'medium', or 'low'.\"))",
  )
}

///|
test "parse_todo_args/error_invalid_status" {
  let args : Json = { "action": "create", "content": "Task", "status": "done" }
  let result : Result[TodoArgs, TodoArgsError] = Ok(parse_todo_args(args)) catch {
    e => Err(e)
  }
  inspect(
    result,
    content="Err(TodoArgsError(\"Error: Invalid status 'String(\\\"done\\\")'. Must be 'pending', 'in_progress', or 'completed'.\"))",
  )
}

///|
test "parse_todo_args/defaults_without_optional_params" {
  let args : Json = { "action": "read" }
  let result = parse_todo_args(args)
  // Verify defaults
  @json.inspect(result, content={
    "action": "Read",
    "priority": "Medium",
    "status": "Pending",
  })
}
