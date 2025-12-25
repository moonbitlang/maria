///|
test "ChatResponseChoice/roundtrip" {
  let original : Array[Json] = [
    { "index": 0, "message": { "role": "assistant", "content": "Hi" } },
    {
      "index": 1,
      "message": { "role": "assistant", "content": "Hi" },
      "finish_reason": "stop",
    },
  ]
  let converted : Array[@openrouter.ChatResponseChoice] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
