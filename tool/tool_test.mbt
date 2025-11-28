///|
test "tool_desc" {
  @json.inspect(
    @tool.tool_desc(
      description="A sample tool",
      name="sample_tool",
      schema=@tool.JsonSchema::from_json({ "type": "object", "properties": {} }),
    ),
    content={
      "description": "A sample tool",
      "name": "sample_tool",
      "schema": { "type": "object", "properties": {} },
    },
  )
}
