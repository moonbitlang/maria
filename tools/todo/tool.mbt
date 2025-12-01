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
  Create
  AddTask
  Update
  MarkProgress
  MarkCompleted
}

///|
async fn Todo::execute_todo(
  self : Todo,
  args : Json,
) -> @tool.ToolResult[TodoResult] noraise {
  // Parse required action parameter
  guard args is { "action": String(action), .. } else {
    return @tool.error("Error: 'action' parameter is required")
  }
  let action = action.to_lower()

  // Handle read action separately
  if action == "read" {
    try {
      self.load()
      return @tool.ok(TodoResult::Read({ todos: self.todos() }))
    } catch {
      error => return @tool.error("Error loading todo list: \{error}", error~)
    }
  }

  // Handle write actions
  let action : Action = match action {
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

///|
pub let prompt : String =
  #|# todo
  #|
  #|## Purpose
  #|
  #|- Create and manage structured task lists for complex coding sessions
  #|- Read and display the current session's todo list to understand task progress
  #|- Track progress on multi-step operations with status updates
  #|- Organize work into manageable, prioritized tasks
  #|- Provide clear progress visibility to users
  #|
  #|## When to Use
  #|
  #|### Reading the Todo List (action='read')
  #|
  #|Use the read action proactively and frequently to ensure awareness of current task status:
  #|
  #|- **At the beginning of conversations** to see what's pending
  #|- **Before starting new tasks** to prioritize work appropriately
  #|- **When the user asks about previous tasks** or plans
  #|- **Whenever you're uncertain about what to do next**
  #|- **After completing tasks** to update understanding of remaining work
  #|- **After every few messages** to ensure you're staying on track
  #|- **Periodically during long sessions** to review progress and stay organized
  #|
  #|The read action takes only the `action` parameter set to 'read'. It returns formatted
  #|output showing tasks grouped by status with summary statistics.
  #|
  #|### Writing/Managing Tasks
  #|
  #|Use write actions (create, add_task, update, mark_progress, mark_completed) proactively in these scenarios, but ONLY AFTER thorough project exploration:
  #|
  #|- **FIRST EXPLORE THE PROJECT**: Always start with project exploration using
  #|  search_files, execute_command, and AC module searches
  #|- **Complex multi-step tasks**: When a task requires 3 or more distinct steps or
  #|  actions
  #|- **Non-trivial and complex tasks**: Tasks that require careful planning or
  #|  multiple operations
  #|- **User explicitly requests todo list**: When the user directly asks you to use
  #|  the todo list
  #|- **User provides multiple tasks**: When users provide a list of things to be
  #|  done (numbered or comma-separated)
  #|- **After receiving new instructions**: Immediately capture user requirements as
  #|  todos, but explore the codebase first
  #|- **When you start working on a task**: Mark it as in_progress BEFORE beginning
  #|  work (ideally only one task should be in_progress at a time)
  #|- **After completing a task**: Mark it as completed and add any new follow-up
  #|  tasks discovered during implementation
  #|
  #|## When NOT to Use
  #|
  #|Skip using this tool when:
  #|
  #|- There is only a **single, straightforward task**
  #|- The task is **trivial** and tracking it provides no organizational benefit
  #|- The task can be completed in **less than 3 trivial steps**
  #|- The task is **purely conversational or informational**
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
  #|
  #|## Example Usage Scenario
  #|
  #|```
  #|User: I want to add a dark mode toggle to the application settings. Make sure you run the tests and build when you're done!
  #|
  #|Assistant: I'll help add a dark mode toggle to your application settings. Let me create a todo list to track this implementation.
  #|
  #|Creates todo list with the following items:
  #|1. Create dark mode toggle component in Settings page
  #|2. Add dark mode state management (context/store)
  #|3. Implement CSS-in-JS styles for dark theme
  #|4. Update existing components to support theme switching
  #|5. Run tests and build process, addressing any failures or errors that occur
  #|
  #|Thinking: The assistant used the todo list because:
  #|1. Adding dark mode is a multi-step feature requiring UI, state management, and styling changes
  #|2. The user explicitly requested tests and build be run afterward
  #|3. The assistant inferred that tests and build need to pass by adding "Ensure tests and build succeed" as the final task
  #|```
  #|
  #|## Workflow Tips
  #|
  #|1. **Read first**: Use 'read' action to check existing todos before planning new work
  #|2. **Start with creation**: Use 'create' action to establish the initial task list for complex projects
  #|3. **Add tasks incrementally**: Use 'add_task' as new requirements emerge during implementation
  #|4. **Track progress actively**: Use 'mark_progress' when starting work on a task
  #|5. **Complete tasks promptly**: Use 'mark_completed' when tasks are finished
  #|6. **Add context**: Use 'notes' parameter to record important decisions or challenges
  #|7. **Review regularly**: Use 'read' action to maintain awareness of overall progress
  #|
  #|By using this TODO tool effectively, you can maintain better organization, provide clear progress visibility, and demonstrate a systematic approach to complex coding tasks.
  #|
  #|IMPORTANT: BEFORE USING TODO TOOL FOR TASK MANAGEMENT, ALWAYS CONDUCT THOROUGH PROJECT EXPLORATION FIRST!
  #|
  #|Begin every task by systematically exploring the project:
  #|
  #|1. Use search_files to understand the project structure and locate relevant files
  #|2. Use execute_command with grep patterns to find specific code patterns and implementations
  #|3. Search for existing AC modules that might provide functionality you can reuse
  #|
  #|Only after gathering sufficient information about the project structure, existing patterns, and available modules should you proceed to planning tasks with TODO tools.
  #|
  #|The TODO tool helps you manage and track task progress during complex coding sessions. It provides structured task management capabilities that enhance productivity and demonstrate thoroughness to users.
  #|
