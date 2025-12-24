///|
test "ChatMessageTokenLogprobs/roundtrip" {
  let original : Array[Json] = [
    {
      "tokens": ["a", "b"],
      "logprobs": [-0.5, -1.0],
      "top_logprobs": [{ "token": "a", "logprob": -0.5 }],
    },
    {
      "tokens": ["a"],
      "logprobs": [-0.5],
      "bytes": "YQ==",
      "top_logprobs": [{ "token": "a", "logprob": -0.5, "bytes": "YQ==" }],
    },
  ]
  let converted : Array[@openrouter.ChatMessageTokenLogprobs] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
