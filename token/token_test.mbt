///|
test "messages" {
  let messages = [
    @openai.user_message(content="Hello"),
    @openai.assistant_message(content="Hi there!"),
  ]
  let counter = @token.Counter::new()
  @json.inspect(counter.count_messages(messages), content=4)
}

///|
test "tool" {
  let tool = @openai.tool(
    name="list_files",
    description="List files in a directory",
    parameters={
      "type": "object",
      "properties": {
        "path": {
          "type": "string",
          "description": "The directory path to list files from",
        },
      },
      "required": ["path"],
    },
  )
  let counter = @token.Counter::new()
  @json.inspect(counter.count_tool(tool), content=70)
}
