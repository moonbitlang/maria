///|
/// Format the response message after todo operations
fn format_todo_response(
  todos : Array[Item],
  action_performed : String,
  updated_todos? : Array[Item],
  is_new_creation~ : Bool,
) -> String {
  if todos.length() == 0 {
    return "Operation completed: \{action_performed}"
  }
  let output = []
  output.push("✅ Operation completed: \{action_performed}\n")

  // Status and priority icon helpers
  fn get_status_icon(status : Status) -> String {
    match status {
      Completed => "✅"
      InProgress => "🔄"
      Pending => "⏳"
    }
  }

  fn get_priority_icon(priority : Priority) -> String {
    match priority {
      High => "🔴"
      Medium => "🟡"
      Low => "🟢"
    }
  }

  // Show newly created todos specifically for create action
  if is_new_creation {
    match updated_todos {
      Some(new_todos) if new_todos.length() > 0 => {
        output.push("📝 Newly created todos:")
        for todo in new_todos {
          let priority_icon = get_priority_icon(todo.priority)
          let status_icon = get_status_icon(todo.status)
          output.push(
            "  \{priority_icon} \{status_icon} [\{todo.id}] \{todo.content}",
          )
        }
      }
      _ => ()
    }
  } else {
    // Always show all todos
    output.push("📝 Current todo list:")
    for todo in todos {
      let priority_icon = get_priority_icon(todo.priority)
      let status_icon = get_status_icon(todo.status)
      output.push(
        "  \{priority_icon} \{status_icon} [\{todo.id}] \{todo.content}",
      )
    }

    // Highlight updated todos if provided
    match updated_todos {
      Some(updated) if updated.length() > 0 => {
        output.push("\n✨ Updated items:")
        for todo in updated {
          let priority_icon = get_priority_icon(todo.priority)
          let status_icon = get_status_icon(todo.status)
          output.push(
            "  \{priority_icon} \{status_icon} [\{todo.id}] \{todo.content}",
          )
        }
      }
      _ => ()
    }
  }
  let total_todos = todos.length()
  let mut pending_count = 0
  let mut in_progress_count = 0
  let mut completed_count = 0
  for todo in todos {
    match todo.status {
      Pending => pending_count = pending_count + 1
      InProgress => in_progress_count = in_progress_count + 1
      Completed => completed_count = completed_count + 1
    }
  }
  output.push(
    "\n📊 Current summary: Total \{total_todos} items | Pending \{pending_count} | In Progress \{in_progress_count} | Completed \{completed_count}",
  )
  output.join("\n")
}

///|
async fn Manager::execute_todo_write(
  self : Manager,
  args : Json,
  _ : @tool.Context,
) -> @tool.Result noraise {
  enum Action {
    Create
    AddTask
    Update
    MarkProgress
    MarkCompleted
  }
  // Parse required action parameter
  guard args is { "action": String(action), .. } else {
    return @tool.error("Error: 'action' parameter is required")
  }
  let action = action.to_lower()
  let action = match action {
    "create" => Create
    "add_task" => AddTask
    "update" => Update
    "mark_progress" => MarkProgress
    "mark_completed" => MarkCompleted
    _ =>
      return @tool.error(
        "Error: Invalid action '\{action}'. Supported actions: create, add_task, update, mark_progress, mark_completed.",
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
  let priority = match args {
    { "priority": p, .. } =>
      match p {
        "high" => High
        "medium" => Medium
        "low" => Low
        _ =>
          return @tool.error(
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
          return @tool.error(
            "Error: Invalid status '\{s}'. Must be 'pending', 'in_progress', or 'completed'.",
          )
      }
    _ => Pending
  }
  let notes : String? = match args {
    { "notes": String(n), .. } => Some(n)
    _ => None
  }
  try {
    self.load() catch {
      error =>
        return @tool.error("Error loading existing todo list: \{error}", error~)
    }
    match action {
      Create =>
        match content {
          None =>
            return @tool.error("Error: Content is required for creating todos.")
          Some(content) => {
            // Clear existing todos and create new ones
            self.parse(content, priority~, notes?) catch {
              error =>
                return @tool.error("Error parsing content: \{error}", error~)
            }
            try {
              self.save()
              let response = format_todo_response(
                self.todos,
                "Created \{self.todos.length()} new todo items",
                updated_todos=self.todos,
                is_new_creation=true,
              )
              return @tool.ok(response)
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
          let response = format_todo_response(
            self.todos,
            "Added new task: \{item.content}",
            updated_todos=[item],
            is_new_creation=false,
          )
          return @tool.ok(response)
        } catch {
          error =>
            return @tool.error("Failed to save new task: \{error}", error~)
        }
      }
      Update | MarkProgress | MarkCompleted => {
        guard task_id is Some(task_id) else {
          return @tool.error(
            "Error: Task ID is required for update operations.",
          )
        }
        guard self.find(task_id) is Some(task_index) else {
          return @tool.error("Error: Task with ID '\{task_id}' not found.")
        }
        let todo = self.get(task_index)
        // Apply specific action
        let updated_todos = []
        let action_message = match action {
          MarkProgress => {
            let updated_todo = todo.update(status=InProgress)
            updated_todos.push(updated_todo)
            self.update_task(task_index, updated_todo)
            "Marked task as in progress: \{updated_todo.content}"
          }
          MarkCompleted => {
            let updated_todo = todo.update(status=Completed)
            updated_todos.push(updated_todo)
            self.update_task(task_index, updated_todo)
            "Marked task as completed: \{updated_todo.content}"
          }
          Update => {
            let updated_todo = todo.update(content?, status~, priority~, notes~)
            updated_todos.push(updated_todo)
            self.update_task(task_index, updated_todo)
            "Updated task: \{updated_todo.content}"
          }
          _ => abort("unreachable")
        }
        try {
          self.save()
          @tool.ok(
            format_todo_response(
              self.todos,
              action_message,
              updated_todos~,
              is_new_creation=false,
            ),
          )
        } catch {
          error =>
            return @tool.error("Failed to save task update: \{error}", error~)
        }
      }
    }
  } catch {
    error => @tool.error("Error in todo write operation: \{error}", error~)
  }
}

///|
pub fn Manager::todo_write(self : Manager) -> @tool.Tool {
  @tool.tool(
    description="Request to create and manage a structured task list for your current coding session. This helps you track progress, organize complex tasks, and demonstrate thoroughness to the user. It also helps the user understand the progress of the task and overall progress of their request. Use this tool proactively for complex multi-step tasks, when explicitly requested by the user, or when you need to organize multiple operations.",
    name="todo_write",
    parameters={
      "type": "object",
      "properties": {
        "action": {
          "type": "string",
          "description": "The action to perform: 'create' (create new todo list), 'add_task' (add single task), 'update' (update existing task), 'mark_progress' (mark task as in progress), 'mark_completed' (mark task as completed)",
        },
        "content": {
          "type": "string",
          "description": "The task content or description (required for create, add_task actions). Can contain <task>...</task> tags for structured input.",
        },
        "task_id": {
          "type": "string",
          "description": "The ID of the task to update (required for update, mark_progress, mark_completed actions)",
        },
        "priority": {
          "type": "string",
          "description": "Task priority level: 'high', 'medium', 'low' (default: 'medium')",
        },
        "status": {
          "type": "string",
          "description": "Task status: 'pending', 'in_progress', 'completed' (default: 'pending')",
        },
        "notes": {
          "type": "string",
          "description": "Additional notes or details about the task",
        },
      },
      "required": ["action"],
    },
    (args, ctx) => self.execute_todo_write(args, ctx),
  )
}
