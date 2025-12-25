///|
test "ChatStreamOptions/roundtrip" {
  let original : Array[Json] = [
    {},
    { "include_usage": true },
    { "include_usage": false },
  ]
  let converted : Array[@openrouter.ChatStreamOptions] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
