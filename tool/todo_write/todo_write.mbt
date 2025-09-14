///|
/// MoonBit implementation of the todo_write tool
///
/// Migrated from TypeScript (todo_write.ts) to MoonBit with the following functionality:
/// - Create new todo lists
/// - Add single tasks
/// - Update existing tasks
/// - Mark tasks as in progress or completed
/// - Task parsing with <task> tags and line-by-line fallback
/// - Compatible with the existing tool interface

///|
/// TodoItem represents a single todo task
priv struct TodoItem {
  content : String
  created_at : String
  id : String
  notes : String?
  priority : String // "high" | "medium" | "low"
  status : String // "pending" | "in_progress" | "completed"
  updated_at : String
} derive(ToJson, FromJson)

///|
/// TodoData represents the entire todo file structure
priv struct TodoData {
  created_at : String
  todos : Array[TodoItem]
  updated_at : String
} derive(ToJson, FromJson)

///|
/// Generate a unique ID for a todo item (simplified version)
fn generate_todo_id() -> String raise {
  let time = @uv.gettimeofday()
  let timestamp = time.sec() * 1000 + time.usec().to_int64() / 1000
  let random_part = timestamp % 100000
  "\{random_part}"
}

///|
/// Get current ISO timestamp
fn get_current_timestamp() -> String raise {
  let _time = @uv.gettimeofday()
  // Simple ISO format - basic implementation
  "2024-01-01T00:00:00.000Z" // Placeholder - in real implementation we'd format properly
}

///|
/// Get the path to the todo file for this session
fn get_todo_file_path(cwd : String) -> Bytes {
  let cwd_bytes = @utf8.encode(cwd)
  let todo_dir = @path.join(cwd_bytes, @utf8.encode(".moonagent"))
  let todo_subdir = @path.join(todo_dir, @utf8.encode("todos"))
  [..@path.join(todo_subdir, @utf8.encode("current_session.json"))]
}

///|
/// Create parent directories if they don't exist
async fn ensure_todo_directory(todo_file : Bytes) -> Unit raise {
  let todo_dir = @path.dirname(todo_file)
  let todo_subdir = @path.dirname(todo_dir)
  let todo_dir_bytes = todo_dir.to_bytes()
  let todo_subdir_bytes = todo_subdir.to_bytes()
  if !@fs.exists(todo_subdir_bytes) {
    @fs.mkdir(todo_subdir_bytes, permission=0o755)
  }
  if !@fs.exists(todo_dir_bytes) {
    @fs.mkdir(todo_dir_bytes, permission=0o755)
  }
}

///|
/// Load todos from the session file
async fn load_todos(cwd : String) -> TodoData raise {
  let todo_file = get_todo_file_path(cwd)
  if !@fs.exists(todo_file) {
    return TodoData::{
      created_at: get_current_timestamp(),
      todos: [],
      updated_at: get_current_timestamp(),
    }
  }
  try {
    let content = @utf8.decode(@fs.read_file(todo_file))
    let json = @json.parse(content)
    @json.from_json(json)
  } catch {
    _ =>
      TodoData::{
        created_at: get_current_timestamp(),
        todos: [],
        updated_at: get_current_timestamp(),
      }
  }
}

///|
/// Save todos to the session file
async fn save_todos(data : TodoData, cwd : String) -> Bool noraise {
  try {
    let todo_file = get_todo_file_path(cwd)
    ensure_todo_directory(todo_file)
    let updated_data = TodoData::{
      created_at: data.created_at,
      todos: data.todos,
      updated_at: get_current_timestamp(),
    }
    let json = updated_data.to_json()
    let content = json.stringify()
    @fs.write_file(todo_file, @utf8.encode(content), create=0o644)
    true
  } catch {
    _ => false
  }
}

///|
/// Create a new todo list from content
fn create_todo_list(
  content : String,
  priority : String,
  notes : String?,
) -> Array[TodoItem] raise {
  let todos = []

  // First, try to parse <task> tags
  let task_matches = extract_task_tags(content)
  if task_matches.length() > 0 {
    // Found <task> tags, use them
    for task_content in task_matches {
      let trimmed = task_content.trim(" \t\r\n").to_string()
      if trimmed.length() > 0 {
        let todo = TodoItem::{
          content: trimmed,
          created_at: get_current_timestamp(),
          id: generate_todo_id(),
          notes,
          priority,
          status: "pending",
          updated_at: get_current_timestamp(),
        }
        todos.push(todo)
      }
    }
  } else {
    // Fallback to line-by-line parsing
    let lines = content.trim(" \t\r\n").to_string().split("\n")
    for line in lines {
      let trimmed_line = line.trim(" \t\r\n").to_string()
      if trimmed_line.length() == 0 {
        continue
      }

      // Remove common prefixes like "1.", "- ", "* ", etc.
      let clean_line = remove_list_prefixes(trimmed_line)
      if clean_line.length() > 0 {
        let todo = TodoItem::{
          content: clean_line,
          created_at: get_current_timestamp(),
          id: generate_todo_id(),
          notes,
          priority,
          status: "pending",
          updated_at: get_current_timestamp(),
        }
        todos.push(todo)
      }
    }
  }
  todos
}

///|
/// Extract content from <task> tags (simplified implementation)
fn extract_task_tags(content : String) -> Array[String] {
  let results = []

  // Simple implementation that finds first <task>...</task> pair
  match content.find("<task>") {
    None => ()
    Some(start_tag) => {
      let content_start = start_tag + 6 // length of "<task>"
      match content.find("</task>") {
        None => ()
        Some(end_tag) =>
          if end_tag > content_start {
            try {
              let task_content = content[content_start:end_tag].to_string()
              results.push(task_content)
            } catch {
              _ => () // ignore slicing errors
            }
          }
      }
    }
  }
  results
}

///|
/// Remove common list prefixes from a line
fn remove_list_prefixes(line : String) -> String {
  let mut result = line

  // Remove numbered list prefixes like "1. ", "2. ", etc.
  if result.has_prefix("1.") ||
    result.has_prefix("2.") ||
    result.has_prefix("3.") ||
    result.has_prefix("4.") ||
    result.has_prefix("5.") ||
    result.has_prefix("6.") ||
    result.has_prefix("7.") ||
    result.has_prefix("8.") ||
    result.has_prefix("9.") {
    let mut i = 0
    while i < result.length() && result[i] >= '0' && result[i] <= '9' {
      i = i + 1
    }
    if i < result.length() && result[i] == '.' {
      i = i + 1
      while i < result.length() && result[i] == ' ' {
        i = i + 1
      }
      try {
        result = result[i:].to_string()
      } catch {
        _ => result = result
      }
    }
  }

  // Remove bullet prefixes like "- " and "* "
  if result.has_prefix("- ") {
    try {
      result = result[2:].to_string()
    } catch {
      _ => result = result
    }
  } else if result.has_prefix("* ") {
    try {
      result = result[2:].to_string()
    } catch {
      _ => result = result
    }
  }
  result.trim(" \t\r\n").to_string()
}

///|
/// Add a single task to the existing todo list
fn add_single_task(
  todos : Array[TodoItem],
  content : String,
  status : String,
  priority : String,
  notes : String?,
) -> TodoItem raise {
  // Check if content contains <task> tags
  let task_matches = extract_task_tags(content)
  let task_content = if task_matches.length() > 0 {
    task_matches[0].trim(" \t\r\n").to_string()
  } else {
    content.trim(" \t\r\n").to_string()
  }
  let todo = TodoItem::{
    content: task_content,
    created_at: get_current_timestamp(),
    id: generate_todo_id(),
    notes,
    priority,
    status,
    updated_at: get_current_timestamp(),
  }
  todos.push(todo)
  todo
}

///|
/// Find a todo item by ID
fn find_todo_by_id(todos : Array[TodoItem], task_id : String) -> TodoItem? {
  for todo in todos {
    if todo.id == task_id {
      return Some(todo)
    }
  }
  None
}

///|
/// Update an existing task
fn update_task(
  todo : TodoItem,
  content : String?,
  status : String?,
  priority : String?,
  notes : String?,
) -> TodoItem raise {
  TodoItem::{
    content: content.unwrap_or_else(fn() { todo.content }),
    created_at: todo.created_at,
    id: todo.id,
    notes: match notes {
      Some(n) => Some(n)
      None => todo.notes
    },
    priority: priority.unwrap_or_else(fn() { todo.priority }),
    status: status.unwrap_or_else(fn() { todo.status }),
    updated_at: get_current_timestamp(),
  }
}

///|
/// Format the response message after todo operations
fn format_todo_response(
  todos : Array[TodoItem],
  action_performed : String,
  updated_todos : Array[TodoItem]?,
  is_new_creation : Bool,
) -> String {
  if todos.length() == 0 {
    return "Operation completed: \{action_performed}"
  }
  let output = []
  output.push("✅ Operation completed: \{action_performed}\n")

  // Status and priority icon helpers
  fn get_status_icon(status : String) -> String {
    match status {
      "completed" => "✅"
      "in_progress" => "🔄"
      "pending" => "⏳"
      _ => "⏳"
    }
  }

  fn get_priority_icon(priority : String) -> String {
    match priority {
      "high" => "🔴"
      "medium" => "🟡"
      "low" => "🟢"
      _ => "⚪"
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
      "pending" => pending_count = pending_count + 1
      "in_progress" => in_progress_count = in_progress_count + 1
      "completed" => completed_count = completed_count + 1
      _ => ()
    }
  }
  output.push(
    "\n📊 Current summary: Total \{total_todos} items | Pending \{pending_count} | In Progress \{in_progress_count} | Completed \{completed_count}",
  )
  output.join("\n")
}

///|
/// Main execution function for the todo_write tool
async fn execute(args : Json, context : @tool.Context) -> @tool.Result noraise {
  // Parse required action parameter
  guard args is { "action": String(action), .. } else {
    return @tool.error("Error: 'action' parameter is required")
  }
  let action = action.to_lower()

  // Parse optional parameters
  let content : String? = match args {
    { "content": String(c), .. } => Some(c)
    _ => None
  }
  let task_id : String? = match args {
    { "task_id": String(t), .. } => Some(t)
    _ => None
  }
  let priority : String = match args {
    { "priority": String(p), .. } => p
    _ => "medium"
  }
  let status : String = match args {
    { "status": String(s), .. } => s
    _ => "pending"
  }
  let notes : String? = match args {
    { "notes": String(n), .. } => Some(n)
    _ => None
  }
  try {
    // Load existing todos
    let data = load_todos(context.cwd)
    let todos = data.todos
    if action == "create" {
      match content {
        None =>
          return @tool.error("Error: Content is required for creating todos.")
        Some(content) => {
          // Clear existing todos and create new ones
          let new_todos = create_todo_list(content, priority, notes)
          let new_data = TodoData::{
            created_at: data.created_at,
            todos: new_todos,
            updated_at: get_current_timestamp(),
          }
          if save_todos(new_data, context.cwd) {
            let response = format_todo_response(
              new_todos,
              "Created \{new_todos.length()} new todo items",
              Some(new_todos),
              true,
            )
            return @tool.ok(response)
          } else {
            return @tool.error("Failed to save todo list.")
          }
        }
      }
    } else if action == "add_task" {
      match content {
        None =>
          return @tool.error("Error: Content is required for adding a task.")
        Some(content) => {
          let new_todo = add_single_task(
            todos, content, status, priority, notes,
          )
          let new_data = TodoData::{
            created_at: data.created_at,
            todos,
            updated_at: get_current_timestamp(),
          }
          if save_todos(new_data, context.cwd) {
            let response = format_todo_response(
              todos,
              "Added new task: \{new_todo.content}",
              Some([new_todo]),
              false,
            )
            return @tool.ok(response)
          } else {
            return @tool.error("Failed to save new task.")
          }
        }
      }
    } else if action == "update" ||
      action == "mark_progress" ||
      action == "mark_completed" {
      match task_id {
        None =>
          return @tool.error(
            "Error: Task ID is required for update operations.",
          )
        Some(task_id) =>
          match find_todo_by_id(todos, task_id) {
            None =>
              return @tool.error("Error: Task with ID '\{task_id}' not found.")
            Some(todo) => {
              // Apply specific action
              let (updated_todo, action_msg) = if action == "mark_progress" {
                let updated = update_task(
                  todo,
                  None,
                  Some("in_progress"),
                  None,
                  None,
                )
                (updated, "Marked task as in progress: \{todo.content}")
              } else if action == "mark_completed" {
                let updated = update_task(
                  todo,
                  None,
                  Some("completed"),
                  None,
                  None,
                )
                (updated, "Marked task as completed: \{todo.content}")
              } else {
                // update
                let updated = update_task(
                  todo,
                  content,
                  Some(status),
                  Some(priority),
                  notes,
                )
                (updated, "Updated task: \{todo.content}")
              }

              // Update the todo in the array
              for i = 0; i < todos.length(); i = i + 1 {
                if todos[i].id == task_id {
                  todos[i] = updated_todo
                  break
                }
              }
              let new_data = TodoData::{
                created_at: data.created_at,
                todos,
                updated_at: get_current_timestamp(),
              }
              if save_todos(new_data, context.cwd) {
                let response = format_todo_response(
                  todos,
                  action_msg,
                  Some([updated_todo]),
                  false,
                )
                return @tool.ok(response)
              } else {
                return @tool.error("Failed to save task update.")
              }
            }
          }
      }
    } else {
      return @tool.error(
        "Error: Unknown action '\{action}'. Supported actions: create, add_task, update, mark_progress, mark_completed.",
      )
    }
  } catch {
    error => @tool.error("Error in todo write operation: \{error}", error~)
  }
}

///|
pub let todo_write : @tool.Tool = @tool.tool(
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
  execute,
)
