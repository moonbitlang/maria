///|
pub fn new(container : Ref[String?]) -> @tool.Tool[String] {
  @tool.new(
    name="attempt_completion",
    description="Once you've completed the task, use this tool to present the result to the user. They may respond with feedback if they are not satisfied with the result, which you can use to make improvements and try again.",
    schema={
      "properties": {
        "result": {
          "description": "The result of the task. Formulate this result in a way that is final and does not require further input from the user. Don't end your result with questions or offers for further assistance.",
          "type": "string",
        },
      },
      "required": ["result"],
      "type": "object",
    },
    @tool.ToolFn(async fn(args) -> @tool.ToolResult[String] noraise {
      guard args is { "result": result, .. } else {
        return @tool.error("Missing 'result' argument")
      }
      guard result is String(result) else {
        return @tool.error("'result' must be a string")
      }
      if container.val is Some(_) {
        container.val = Some(result)
        @tool.ok("Task result updated.")
      } else {
        container.val = Some(result)
        @tool.ok("Task result created.")
      }
    }),
  )
}
