///|
test "ToolResponseMessage/roundtrip" {
  let original : Array[Json] = [
    { "role": "tool", "tool_call_id": "call_1", "content": "Tool response" },
    { "role": "tool", "tool_call_id": "call_2", "content": "{}" },
  ]
  let converted : Array[@message.ToolResponseMessage] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
