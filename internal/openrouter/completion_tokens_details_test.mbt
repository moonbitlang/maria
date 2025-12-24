///|
test "CompletionTokensDetails/roundtrip" {
  let original : Array[Json] = [
    {},
    { "reasoning_tokens": 0 },
    { "reasoning_tokens": 7 },
  ]
  let converted : Array[@openrouter.CompletionTokensDetails] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
