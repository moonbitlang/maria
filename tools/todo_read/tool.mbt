///|
struct TodoReadResult {
  todos : Array[@todo.Item]
} derive(ToJson, FromJson)

///|
pub impl Show for TodoReadResult with output(
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
let schema : @tool.JsonSchema = {
  "type": "object",
  "properties": {},
  "required": [],
}

///|
pub fn new(list : @todo.Todo) -> @tool.Tool[TodoReadResult] {
  @tool.new(
    description="Request to read the current todo list for the session. This tool helps you track progress, organize complex tasks, and understand the current status of ongoing work. Use this tool proactively to stay aware of task progress and demonstrate thoroughness.",
    name="todo_read",
    schema~,
    async fn(_) -> @tool.ToolResult[TodoReadResult] noraise {
      @tool.ok({ todos: list.todos() })
    },
  )
}

///|
pub let prompt : String =
  #|# todo_read
  #|
  #|## Purpose
  #|
  #|- Read and display the current session's todo list to understand task progress
  #|- Get an overview of all pending, in-progress, and completed tasks
  #|- Track the status of complex multi-step operations
  #|
  #|## When to Use
  #|
  #|Use this tool proactively and frequently to ensure awareness of current task
  #|status:
  #|
  #|- **At the beginning of conversations** to see what's pending
  #|- **Before starting new tasks** to prioritize work appropriately
  #|- **When the user asks about previous tasks** or plans
  #|- **Whenever you're uncertain about what to do next**
  #|- **After completing tasks** to update understanding of remaining work
  #|- **After every few messages** to ensure you're staying on track
  #|- **Periodically during long sessions** to review progress and stay organized
  #|
  #|## Important Considerations
  #|
  #|- This tool takes **no parameters** - leave the input completely blank or empty
  #|- **DO NOT** include dummy objects, placeholder strings, or keys like "input" or
  #|  "empty"
  #|- **LEAVE IT BLANK** - the tool will automatically read the current session's
  #|  todo list
  #|- Returns formatted output showing tasks grouped by status (In Progress,
  #|  Pending, Completed)
  #|- Provides summary statistics about task completion rates
  #|
  #|## Benefits
  #|
  #|- Helps maintain context and continuity across complex tasks
  #|- Provides clear visibility into what has been accomplished and what remains
  #|- Demonstrates organized approach to problem-solving
  #|- Helps prioritize next steps based on current task status
  #|
