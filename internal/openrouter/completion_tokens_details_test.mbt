///|
test "CompletionTokensDetails/roundtrip" {
  let original : Array[Json] = [
    {},
    { "reasoning_tokens": 0 },
    { "reasoning_tokens": 7 },
  ]
  let converted : Array[@openrouter.CompletionTokensDetails] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
