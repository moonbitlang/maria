///|
/// TodoResult - Unified result for all todo operations
struct TodoResult {
  todos : Array[Item]
  message : String?
  updated_todos : Array[Item]?
  is_new_creation : Bool?
} derive(ToJson, FromJson)

///|
pub impl Show for TodoResult with output(self : TodoResult, logger : &Logger) -> Unit {
  let todos = self.todos
  let output = []

  // Check if this is a read action (no message means read)
  if self.message is None {
    // Display for read action
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
  } else {
    // Display for write actions
    let action_performed = self.message.unwrap()
    let updated_todos = self.updated_todos.unwrap_or([])
    let is_new_creation = self.is_new_creation.unwrap_or(false)
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
  }
  logger.write_string(output.join("\n"))
}

///|
let todo_schema : @tool.JsonSchema = {
  "type": "object",
  "properties": {
    "action": {
      "type": "string",
      "description": "The action to perform: 'read' (read todo list), 'create' (create new todo list), 'add_task' (add single task), 'update' (update existing task), 'mark_progress' (mark task as in progress), 'mark_completed' (mark task as completed)",
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
}

///|
pub fn new_tool(list : Todo) -> @tool.Tool[TodoResult] {
  @tool.new(
    description="Request to read and manage the todo list for the current coding session. This tool helps you track progress, organize complex tasks, and demonstrate thoroughness. Use 'read' action to view current todos, or use write actions (create, add_task, update, mark_progress, mark_completed) to manage tasks.",
    name="todo",
    schema=todo_schema,
    async fn(args) -> @tool.ToolResult[TodoResult] noraise {
      list.execute_todo(args)
    },
  )
}

///|
pub let prompt : String =
  #|# todo
  #|
  #|## Purpose
  #|
  #|- Read and display the current session's todo list to understand task progress
  #|- Create and manage structured task lists for complex coding sessions
  #|- Track progress on multi-step operations with status updates
  #|- Organize work into manageable, prioritized tasks
  #|- Provide clear progress visibility to users
  #|
  #|## Available Actions
  #|
  #|### read
  #|- View the current todo list without making any changes
  #|- Usage: `<todo action='read'/>`
  #|- Takes no additional parameters
  #|- Returns formatted output showing tasks grouped by status
  #|
  #|### create
  #|- Clear existing todos and create a new todo list
  #|- Required: `content` (task description or numbered list)
  #|- Optional: `priority`, `notes`
  #|- Use for starting fresh with a new set of tasks
  #|
  #|### add_task
  #|- Add a single task to the existing todo list
  #|- Required: `content` (task description)
  #|- Optional: `status`, `priority`, `notes`
  #|- Use when new requirements emerge during implementation
  #|
  #|### update
  #|- Modify an existing task's properties
  #|- Required: `task_id`
  #|- Optional: `content`, `status`, `priority`, `notes`
  #|- Use to refine or adjust existing tasks
  #|
  #|### mark_progress
  #|- Mark a task as in-progress
  #|- Required: `task_id`
  #|- Use BEFORE starting work on a task (ideally only one task should be in-progress at a time)
  #|
  #|### mark_completed
  #|- Mark a task as completed
  #|- Required: `task_id`
  #|- Use IMMEDIATELY after finishing a task
  #|
  #|## When to Use
  #|
  #|Use this tool proactively in these scenarios:
  #|
  #|### Read Action
  #|- **At the beginning of conversations** to see what's pending
  #|- **Before starting new tasks** to prioritize work appropriately
  #|- **When the user asks about previous tasks** or plans
  #|- **Whenever you're uncertain about what to do next**
  #|- **After completing tasks** to update understanding of remaining work
  #|- **After every few messages** to ensure you're staying on track
  #|- **Periodically during long sessions** to review progress and stay organized
  #|
  #|### Write Actions
  #|**IMPORTANT: FIRST EXPLORE THE PROJECT** - Always start with project exploration using
  #|search_files, execute_command, and AC module searches before creating todos
  #|
  #|- **Complex multi-step tasks**: When a task requires 3 or more distinct steps or actions
  #|- **Non-trivial and complex tasks**: Tasks that require careful planning or multiple operations
  #|- **User explicitly requests todo list**: When the user directly asks you to use the todo list
  #|- **User provides multiple tasks**: When users provide a list of things to be done (numbered or comma-separated)
  #|- **After receiving new instructions**: Immediately capture user requirements as todos, but explore the codebase first
  #|- **When you start working on a task**: Mark it as in_progress BEFORE beginning work
  #|- **After completing a task**: Mark it as completed and add any new follow-up tasks discovered during implementation
  #|
  #|## When NOT to Use
  #|
  #|Skip using this tool when:
  #|
  #|- There is only a **single, straightforward task**
  #|- The task is **trivial** and tracking it provides no organizational benefit
  #|- The task can be completed in **less than 3 trivial steps**
  #|- The task is **purely conversational or informational**
  #|- Just reading files or performing simple searches
  #|
  #|**NOTE**: Do not use this tool if there is only one trivial task to do. In this
  #|case you are better off just doing the task directly.
  #|
  #|## Important Considerations
  #|
  #|- Each task gets a unique ID that can be used for future updates
  #|- Task content for 'create' action should be formatted as a numbered list for multiple tasks
  #|- The system automatically tracks task creation and modification timestamps
  #|- Todo lists persist across tool calls within the same session
  #|- Use descriptive task names that clearly indicate what needs to be accomplished
  #|- Mark todos completed as soon as they are done - do not batch completions
  #|
  #|## Example Usage Scenarios
  #|
  #|### Reading Todos
  #|```
  #|User: What tasks are we working on?
  #|
  #|Assistant: Let me check the current todo list.
  #|[Calls tool with: {"action": "read"}]
  #|```
  #|
  #|### Creating Todo List
  #|```
  #|User: I want to add a dark mode toggle to the application settings. Make sure you run the tests and build when you're done!
  #|
  #|Assistant: I'll help add a dark mode toggle to your application settings. Let me create a todo list to track this implementation.
  #|
  #|[Creates todo list with:
  #|{
  #|  "action": "create",
  #|  "content": "1. Create dark mode toggle component in Settings page\\n2. Add dark mode state management (context/store)\\n3. Implement CSS-in-JS styles for dark theme\\n4. Update existing components to support theme switching\\n5. Run tests and build process, addressing any failures or errors that occur"
  #|}]
  #|
  #|Thinking: The assistant used the todo list because:
  #|1. Adding dark mode is a multi-step feature requiring UI, state management, and styling changes
  #|2. The user explicitly requested tests and build be run afterward
  #|3. The assistant inferred that tests and build need to pass by adding "Ensure tests and build succeed" as the final task
  #|```
  #|
  #|## Workflow Tips
  #|
  #|1. **Start with exploration**: Use search and analysis tools to understand the project first
  #|2. **Create initial plan**: Use 'create' action to establish the initial task list for complex projects
  #|3. **Read regularly**: Use 'read' action frequently to maintain awareness of overall progress
  #|4. **Add tasks incrementally**: Use 'add_task' as new requirements emerge during implementation
  #|5. **Track progress actively**: Use 'mark_progress' when starting work on a task
  #|6. **Complete tasks promptly**: Use 'mark_completed' when tasks are finished - do not batch completions
  #|7. **Add context**: Use 'notes' parameter to record important decisions or challenges
  #|
  #|By using this TODO tool effectively, you can maintain better organization, provide clear progress visibility, and demonstrate a systematic approach to complex coding tasks.
  #|

///|
async fn Todo::execute_todo(
  self : Todo,
  args : Json,
) -> @tool.ToolResult[TodoResult] noraise {
  enum Action {
    Read
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
    "read" => Read
    "create" => Create
    "add_task" => AddTask
    "update" => Update
    "mark_progress" => MarkProgress
    "mark_completed" => MarkCompleted
    _ =>
      return @tool.error(
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
  self.load() catch {
    error =>
      return @tool.error("Error loading existing todo list: \{error}", error~)
  }
  match action {
    Read =>
      // Simple read action - just return current todos
      return @tool.ok({
        todos: self.todos(),
        message: None,
        updated_todos: None,
        is_new_creation: None,
      })
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
            return @tool.ok({
              todos,
              message: Some("Created \{todos.length()} new todo items"),
              updated_todos: Some(todos),
              is_new_creation: Some(true),
            })
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
        return @tool.ok(TodoResult::{
          todos: self.todos().map(t => t),
          message: Some("Added new task: \{item.content}"),
          updated_todos: Some([item]),
          is_new_creation: Some(false),
        })
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
        @tool.ok(TodoResult::{
          todos: self.todos(),
          message: Some(action_message),
          updated_todos: Some(updated_todos),
          is_new_creation: Some(false),
        })
      } catch {
        error =>
          return @tool.error("Failed to save task update: \{error}", error~)
      }
    }
  }
}
