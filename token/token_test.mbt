///|
test "messages" {
  let messages = [
    @openai.user_message(content="Hello"),
    @openai.assistant_message(content="Hi there!"),
  ]
  let counter = @token.Counter::new()
  counter.add_messages(messages)
  @json.inspect(counter.count(), content=11)
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
  counter.add_tool(tool)
  @json.inspect(counter.count(), content=397)
}
