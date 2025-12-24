///|
test "TopLogprob/roundtrip" {
  let original : Array[Json] = [
    { "token": "hello", "logprob": -0.10000000149011612, "bytes": "aGVsbG8=" },
    { "token": "world", "logprob": -1.5 },
  ]
  let converted : Array[@openrouter.TopLogprob] = from_json_array(original)
  assert_eq(to_json_array(converted), original)
}
