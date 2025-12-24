///|
test "ChatGenerationTokenUsage/roundtrip" {
  let original : Array[Json] = [
    { "completion_tokens": 2, "prompt_tokens": 1, "total_tokens": 3 },
    {
      "completion_tokens": 2,
      "prompt_tokens": 1,
      "total_tokens": 3,
      "prompt_tokens_details": { "cached_tokens": 1 },
      "completion_tokens_details": { "reasoning_tokens": 2 },
    },
  ]
  let converted : Array[@openrouter.ChatGenerationTokenUsage] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
