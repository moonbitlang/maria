///|
/// MoonBit implementation of the todo_read tool
///
/// Migrated from TypeScript (todo_read.ts) to MoonBit with the following functionality:
/// - Read current session's todo list
/// - Format todos with status and priority indicators  
/// - Provide summary statistics
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
/// Get the path to the todo file for this session
fn get_todo_file_path(cwd : @string.View) -> @string.View {
  let todo_dir = @path.join(cwd, ".moonagent")
  let todo_subdir = @path.join(todo_dir, "todos")
  @path.join(todo_subdir, "current_session.json")
}

///|
/// Load todos from the session file
async fn load_todos(cwd : String) -> Array[TodoItem] raise {
  let todo_file = get_todo_file_path(cwd)
  if !@fs.exists(todo_file) {
    return []
  }
  try {
    let content = @fs.read_file(todo_file)
    let json = @json.parse(content)
    let data : TodoData = @json.from_json(json)
    data.todos
  } catch {
    _ =>
      // Log warning but return empty array to continue gracefully
      []
  }
}

///|
/// Format todos for display with emojis and structure
fn format_todo_display(todos : Array[TodoItem]) -> String {
  if todos.length() == 0 {
    return "No todos found for this session."
  }
  let output = []
  output.push("=== Current Session Todo List ===\n")

  // Status emoji mapping
  fn get_status_emoji(status : String) -> String {
    match status {
      "completed" => "✅"
      "in_progress" => "🔄"
      "pending" => "⏳"
      _ => "❓"
    }
  }

  // Priority icon mapping  
  fn get_priority_icon(priority : String) -> String {
    match priority {
      "high" => "🔴"
      "medium" => "🟡"
      "low" => "🟢"
      _ => "⚪"
    }
  }

  // Display todos in a single list with status markers
  for i = 0; i < todos.length(); i = i + 1 {
    let todo = todos[i]
    let status_mark = get_status_emoji(todo.status)
    let priority_mark = get_priority_icon(todo.priority)

    // Format each todo item
    output.push(
      "\{i + 1}. \{status_mark} \{priority_mark} [\{todo.id}] \{todo.content}",
    )

    // Add notes if present
    match todo.notes {
      Some(notes) => output.push("   └─ 📝 \{notes}")
      None => ()
    }
  }
  output.push("")

  // Add summary statistics
  let total = todos.length()
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
  let summary_parts = ["Total: \{total}"]
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
  output.join("\n")
}

///|
/// Main execution function for the todo_read tool
async fn execute(_ : Json, context : @tool.Context) -> @tool.Result noraise {
  try {
    // Load todos from file
    let todos = load_todos(context.cwd)

    // Format for display
    let formatted_display = format_todo_display(todos)
    @tool.ok(formatted_display)
  } catch {
    error => @tool.error("Error reading todo list: \{error}", error~)
  }
}

///|
pub let todo_read : @tool.Tool = @tool.tool(
  description="Request to read the current todo list for the session. This tool helps you track progress, organize complex tasks, and understand the current status of ongoing work. Use this tool proactively to stay aware of task progress and demonstrate thoroughness.",
  name="todo_read",
  parameters={ "type": "object", "properties": {}, "required": [] },
  execute,
)
