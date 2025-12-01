///| Tests for parse_todo_args

///|
test "parse_todo_args/read_action" {
  let args : Json = { "action": "read" }
  let result = parse_todo_args(args)
  inspect(result.action, content="Read")
  inspect(result.content, content="None")
  inspect(result.task_id, content="None")
  inspect(result.priority, content="Medium")
  inspect(result.status, content="Pending")
  inspect(result.notes, content="None")
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
  inspect(result.action, content="Create")
  inspect(result.content, content="Some(\"Test task\")")
  inspect(result.priority, content="High")
  inspect(result.status, content="Pending")
  inspect(result.notes, content="Some(\"Some notes\")")
}

///|
test "parse_todo_args/add_task_action" {
  let args : Json = { "action": "add_task", "content": "New task" }
  let result = parse_todo_args(args)
  inspect(result.action, content="AddTask")
  inspect(result.content, content="Some(\"New task\")")
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
  inspect(result.action, content="Update")
  inspect(result.task_id, content="Some(\"abc123\")")
  inspect(result.content, content="Some(\"Updated content\")")
  inspect(result.priority, content="Low")
}

///|
test "parse_todo_args/mark_progress_action" {
  let args : Json = { "action": "mark_progress", "task_id": "task-1" }
  let result = parse_todo_args(args)
  inspect(result.action, content="MarkProgress")
  inspect(result.task_id, content="Some(\"task-1\")")
}

///|
test "parse_todo_args/mark_completed_action" {
  let args : Json = { "action": "mark_completed", "task_id": "task-2" }
  let result = parse_todo_args(args)
  inspect(result.action, content="MarkCompleted")
  inspect(result.task_id, content="Some(\"task-2\")")
}

///|
test "parse_todo_args/case_insensitive_action" {
  let args : Json = { "action": "CREATE", "content": "Task" }
  let result = parse_todo_args(args)
  inspect(result.action, content="Create")
}

///|
test "parse_todo_args/status_in_progress_hyphen" {
  let args : Json = {
    "action": "add_task",
    "content": "Task",
    "status": "in-progress",
  }
  let result = parse_todo_args(args)
  inspect(result.status, content="InProgress")
}

///|
test "parse_todo_args/status_in_progress_underscore" {
  let args : Json = {
    "action": "add_task",
    "content": "Task",
    "status": "in_progress",
  }
  let result = parse_todo_args(args)
  inspect(result.status, content="InProgress")
}

///|
test "parse_todo_args/status_completed" {
  let args : Json = {
    "action": "add_task",
    "content": "Task",
    "status": "completed",
  }
  let result = parse_todo_args(args)
  inspect(result.status, content="Completed")
}

///|
test "parse_todo_args/priority_medium" {
  let args : Json = {
    "action": "create",
    "content": "Task",
    "priority": "medium",
  }
  let result = parse_todo_args(args)
  inspect(result.priority, content="Medium")
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
  inspect(result.content, content="None")
  inspect(result.task_id, content="None")
  inspect(result.priority, content="Medium")
  inspect(result.status, content="Pending")
  inspect(result.notes, content="None")
}
