///|
test "ToolDefinitionJson/roundtrip" {
  let original : Array[Json] = [
    { "name": "my_tool" },
    { "name": "my_tool", "description": "does things" },
  ]
  let converted : Array[@openrouter.ToolDefinitionJson] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
