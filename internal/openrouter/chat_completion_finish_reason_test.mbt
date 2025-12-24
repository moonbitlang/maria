///|
test "ChatCompletionFinishReason/roundtrip" {
  let original : Array[Json] = [
    "stop", "length", "tool_calls", "content_filter",
  ]
  let converted : Array[@openrouter.ChatCompletionFinishReason] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
