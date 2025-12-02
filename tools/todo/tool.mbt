///|
enum TodoResult {
  Read(TodoReadResult)
  Write(TodoWriteResult)
} derive(ToJson, FromJson)

///|
pub impl Show for TodoResult with output(self : TodoResult, logger : &Logger) -> Unit {
  match self {
    Read(result) => result.output(logger)
    Write(result) => result.output(logger)
  }
}

///|
/// TodoReadResult
priv struct TodoReadResult {
  todos : Array[Item]
} derive(ToJson, FromJson)

///|
impl Show for TodoReadResult with output(
  self : TodoReadResult,
  logger : &Logger,
) -> Unit {
  let todos = self.todos
  let output = []
  output.push("=== Current Session Todo List ===\n")
  let mut pending_count = 0
  let mut in_progress_count = 0
  let mut completed_count = 0
  // Display todos in a single list with status markers
  for i, todo in todos {
    output.push(
      "\{i + 1}. \{todo.status.icon()} \{todo.priority.icon()} [\{todo.id}] \{todo.content}",
    )
    if todo.notes is Some(notes) {
      output.push("   └─ 📝 \{notes}")
    }
    match todo.status {
      Pending => pending_count += 1
      InProgress => in_progress_count += 1
      Completed => completed_count += 1
    }
  }
  output.push("")
  let summary_parts = ["Total: \{todos.length()}"]
  if completed_count > 0 {
    summary_parts.push("✅ Completed: \{completed_count}")
  }
  if in_progress_count > 0 {
    summary_parts.push("🔄 In Progress: \{in_progress_count}")
  }
  if pending_count > 0 {
    summary_parts.push("⏳ Pending: \{pending_count}")
  }
  output.push("📊 Summary: " + summary_parts.join(" | "))
  logger.write_string(output.join("\n"))
}

///|
pub fn new_tool(list : Todo) -> @tool.Tool[TodoResult] {
  @tool.new(
    description="Request to manage the todo list for the session. This tool helps you track progress, organize complex tasks, and understand the current status of ongoing work. Use this tool proactively to stay aware of task progress and demonstrate thoroughness.",
    name="todo",
    schema=todo_schema,
    async fn(args) -> @tool.ToolResult[TodoResult] noraise {
      list.execute_todo(args)
    },
  )
}

///|
/// TodoWriteResult
priv struct TodoWriteResult {
  todos : Array[Item]
  message : String
  updated_todos : Array[Item]
  is_new_creation : Bool
} derive(ToJson, FromJson)

///|
impl Show for TodoWriteResult with output(
  self : TodoWriteResult,
  logger : &Logger,
) -> Unit {
  let todos = self.todos
  let action_performed = self.message
  let updated_todos = self.updated_todos
  let is_new_creation = self.is_new_creation
  let output = []
  output.push("✅ Operation completed: \{action_performed}\n")
  fn output_todos(todos : Array[Item]) {
    for todo in todos {
      output.push(
        "  \{todo.priority.icon()} \{todo.status.icon()} [\{todo.id}] \{todo.content}",
      )
    }
  }
  // Show newly created todos specifically for create action
  if is_new_creation {
    if updated_todos.length() > 0 {
      output.push("📝 Newly created todos:")
      output_todos(updated_todos)
    }
  } else {
    // Always show all todos
    output.push("📝 Current todo list:")
    output_todos(todos)

    // Highlight updated todos if provided
    if updated_todos.length() > 0 {
      output.push("\n✨ Updated items:")
      output_todos(updated_todos)
    }
  }
  let mut pending_count = 0
  let mut in_progress_count = 0
  let mut completed_count = 0
  for todo in todos {
    match todo.status {
      Pending => pending_count += 1
      InProgress => in_progress_count += 1
      Completed => completed_count += 1
    }
  }
  output.push(
    "\n📊 Current summary: Total \{todos.length()} items | Pending \{pending_count} | In Progress \{in_progress_count} | Completed \{completed_count}",
  )
  logger.write_string(output.join("\n"))
}

///|
priv enum Action {
  Read
  Create
  AddTask
  Update
  MarkProgress
  MarkCompleted
} derive(Show, ToJson)

///|
/// Parsed arguments from JSON input for todo operations
struct TodoArgs {
  action : Action
  content : String?
  task_id : String?
  priority : Priority
  status : Status
  notes : String?
} derive(Show, ToJson)

///|
/// Parse error type for todo arguments
suberror TodoArgsError String derive(Show)

///|
/// Parse JSON arguments into TodoArgs
pub fn parse_todo_args(args : Json) -> TodoArgs raise TodoArgsError {
  // Parse required action parameter
  guard args is { "action": String(action), .. } else {
    raise TodoArgsError("Error: 'action' parameter is required")
  }
  let action : Action = match action.to_lower() {
    "read" => Read
    "create" => Create
    "add_task" => AddTask
    "update" => Update
    "mark_progress" => MarkProgress
    "mark_completed" => MarkCompleted
    _ =>
      raise TodoArgsError(
        "Error: Invalid action '\{action}'. Supported actions: read, create, add_task, update, mark_progress, mark_completed.",
      )
  }

  // Parse optional parameters
  let content : String? = match args {
    { "content": String(c), .. } => Some(c)
    _ => None
  }
  let task_id : String? = match args {
    { "task_id": String(t), .. } => Some(t)
    _ => None
  }
  let priority : Priority = match args {
    { "priority": p, .. } =>
      match p {
        "high" => High
        "medium" => Medium
        "low" => Low
        _ =>
          raise TodoArgsError(
            "Error: Invalid priority '\{p}'. Must be 'high', 'medium', or 'low'.",
          )
      }
    _ => Medium
  }
  let status : Status = match args {
    { "status": s, .. } =>
      match s {
        "pending" => Pending
        "in_progress" | "in-progress" => InProgress
        "completed" => Completed
        _ =>
          raise TodoArgsError(
            "Error: Invalid status '\{s}'. Must be 'pending', 'in_progress', or 'completed'.",
          )
      }
    _ => Pending
  }
  let notes : String? = match args {
    { "notes": String(n), .. } => Some(n)
    _ => None
  }
  { action, content, task_id, priority, status, notes }
}

///|
async fn Todo::execute_todo(
  self : Todo,
  args : Json,
) -> @tool.ToolResult[TodoResult] noraise {
  let todo_args = parse_todo_args(args) catch {
    TodoArgsError(msg) => return @tool.error(msg)
  }
  self.load() catch {
    error =>
      return @tool.error("Error loading existing todo list: \{error}", error~)
  }
  // Handle read action
  if todo_args.action is Read {
    return @tool.ok(TodoResult::Read({ todos: self.todos() }))
  }
  let { action, content, task_id, priority, status, notes } = todo_args
  match action {
    Read => abort("unreachable") // Already handled above
    Create =>
      match content {
        None =>
          return @tool.error("Error: Content is required for creating todos.")
        Some(content) => {
          // Clear existing todos and create new ones
          self.parse(content, priority~, notes?)
          try {
            self.save()
            let todos = self.todos()
            return @tool.ok(
              TodoResult::Write({
                todos,
                message: "Created \{todos.length()} new todo items",
                updated_todos: todos,
                is_new_creation: true,
              }),
            )
          } catch {
            error =>
              return @tool.error("Failed to save todo list: \{error}", error~)
          }
        }
      }
    AddTask => {
      guard content is Some(content) else {
        return @tool.error("Error: Content is required for adding a task.")
      }
      let item = self.add_task(content, status~, priority~, notes~)
      try {
        self.save()
        return @tool.ok(
          TodoResult::Write({
            todos: self.todos().map(t => t),
            message: "Added new task: \{item.content}",
            updated_todos: [item],
            is_new_creation: false,
          }),
        )
      } catch {
        error => return @tool.error("Failed to save new task: \{error}", error~)
      }
    }
    Update | MarkProgress | MarkCompleted => {
      guard task_id is Some(task_id) else {
        return @tool.error("Error: Task ID is required for update operations.")
      }
      guard self.find(task_id) is Some(task_index) else {
        return @tool.error("Error: Task with ID '\{task_id}' not found.")
      }
      let todo = self.get(task_index)
      // Apply specific action
      let updated_todos = []
      let action_message = match action {
        MarkProgress => {
          let updated_todo = todo.update(
            status=InProgress,
            updated_at=self.now(),
          )
          updated_todos.push(updated_todo)
          self.update_task(task_index, updated_todo)
          "Marked task as in progress: \{updated_todo.content}"
        }
        MarkCompleted => {
          let updated_todo = todo.update(
            status=Completed,
            updated_at=self.now(),
          )
          updated_todos.push(updated_todo)
          self.update_task(task_index, updated_todo)
          "Marked task as completed: \{updated_todo.content}"
        }
        Update => {
          let updated_todo = todo.update(
            content?,
            status~,
            priority~,
            notes~,
            updated_at=self.now(),
          )
          updated_todos.push(updated_todo)
          self.update_task(task_index, updated_todo)
          "Updated task: \{updated_todo.content}"
        }
        _ => abort("unreachable")
      }
      try {
        self.save()
        @tool.ok(
          TodoResult::Write({
            todos: self.todos(),
            message: action_message,
            updated_todos,
            is_new_creation: false,
          }),
        )
      } catch {
        error =>
          return @tool.error("Failed to save task update: \{error}", error~)
      }
    }
  }
}
