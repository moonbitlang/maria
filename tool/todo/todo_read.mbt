///|
pub fn Manager::get_todo_read_tool(self : Manager) -> @tool.Tool {
  @tool.tool(
    description="Request to read the current todo list for the session. This tool helps you track progress, organize complex tasks, and understand the current status of ongoing work. Use this tool proactively to stay aware of task progress and demonstrate thoroughness.",
    name="todo_read",
    parameters={ "type": "object", "properties": {}, "required": [] },
    (_, _) => @tool.ok(self.display()),
  )
}
