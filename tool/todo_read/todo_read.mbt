///|
/// Main execution function for the todo_read tool
async fn execute(_ : Json, context : @tool.Context) -> @tool.Result noraise {
  try {
    let manager = @todo.Manager::new(cwd=context.cwd)
    manager.load()
    @tool.ok(manager.display())
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
