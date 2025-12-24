///|
test "ChatMessageToolCall/roundtrip" {
  let original : Array[Json] = [
    { "type": "function", "function": { "name": "my_tool", "arguments": "{}" } },
  ]
  let converted : Array[@openrouter.ChatMessageToolCall] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
