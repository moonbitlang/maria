///|
test "UserMessageContent/roundtrip" {
  let original : Array[Json] = [
    "Hello, world!",
    [{ "type": "text", "text": "Item 1" }],
    [{ "type": "text", "text": "Item 1" }, { "type": "text", "text": "Item 2" }],
  ]
  let converted : Array[@openrouter.UserMessageContent] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
