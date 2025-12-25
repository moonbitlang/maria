///|
test "ChatMessageToolCall/roundtrip" {
  let original : Array[Json] = [
    { "type": "function", "function": { "name": "my_tool", "arguments": "{}" } },
  ]
  let converted : Array[@chat_message.ChatMessageToolCall] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
