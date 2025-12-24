///|
test "ChatMessageTokenLogprob/roundtrip" {
  let original : Array[Json] = [
    { "token": "a", "logprob": -0.5, "bytes": "YQ==" },
    {
      "token": "b",
      "logprob": -1.0,
      "bytes": "Yg==",
      "top_logprobs": [{ "token": "b", "logprob": -1.0, "bytes": "Yg==" }],
    },
  ]
  let converted : Array[@openrouter.ChatMessageTokenLogprob] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
