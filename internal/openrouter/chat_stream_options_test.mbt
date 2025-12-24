///|
test "ChatStreamOptions/roundtrip" {
  let original : Array[Json] = [
    {},
    { "include_usage": true },
    { "include_usage": false },
  ]
  let converted : Array[@openrouter.ChatStreamOptions] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
