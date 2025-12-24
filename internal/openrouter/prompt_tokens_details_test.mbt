///|
test "PromptTokensDetails/roundtrip" {
  let original : Array[Json] = [
    {},
    { "cached_tokens": 0 },
    { "cached_tokens": 12 },
  ]
  let converted : Array[@openrouter.PromptTokensDetails] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
