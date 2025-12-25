///|
test "ToolDefinitionJson/roundtrip" {
  let original : Array[Json] = [
    { "name": "my_tool" },
    { "name": "my_tool", "description": "does things" },
  ]
  let converted : Array[@chat_generation_params.ToolDefinitionJson] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
