///|
pub(all) struct TodoReadResult {
  todos : Array[Item]
} derive(ToJson, FromJson)
<<<<<<< HEAD

=======
>>>>>>> f571711 (Add structured JSON output for tool functions and create PR fetch script)
///|
pub let read : @tool.Tool[List] = @tool.tool(
  description="Request to read the current todo list for the session. This tool helps you track progress, organize complex tasks, and understand the current status of ongoing work. Use this tool proactively to stay aware of task progress and demonstrate thoroughness.",
  name="todo_read",
  parameters={ "type": "object", "properties": {}, "required": [] },
  (_, self) => @tool.ok(TodoReadResult::{ todos: self.todos }.to_json()),
  render=result => {
    let todos : Array[Item] = @json.from_json(result.output) catch {
      error => return "Error: Unexpected output format: \{error}"
    }
    if todos.length() == 0 {
      return "No todos found for this session."
    }
    let output = []
    output.push("=== Current Session Todo List ===\n")

    // Status emoji mapping
    fn get_status_emoji(status : Status) -> String {
      match status {
        Status::Completed => "✅"
        Status::InProgress => "🔄"
        Status::Pending => "⏳"
      }
    }

    // Priority icon mapping
    fn get_priority_icon(priority : Priority) -> String {
      match priority {
        Priority::High => "🔴"
        Priority::Medium => "🟡"
        Priority::Low => "🟢"
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
        Status::Pending => pending_count = pending_count + 1
        Status::InProgress => in_progress_count = in_progress_count + 1
        Status::Completed => completed_count = completed_count + 1
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
  },
)
