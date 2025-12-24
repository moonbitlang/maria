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
  let converted : Array[@openrouter.ChatResponseChoice] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
