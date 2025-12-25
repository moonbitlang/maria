///|
test "ChatCompletionFinishReason/roundtrip" {
  let original : Array[Json] = [
    "stop", "length", "tool_calls", "content_filter",
  ]
  let converted : Array[@openrouter.ChatCompletionFinishReason] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
