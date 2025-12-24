///|
test "SystemMessageContent/roundtrip" {
  let original : Array[Json] = [
    "Hello, system!",
    [{ "type": "text", "text": "Item 1" }],
  ]
  let converted : Array[@openrouter.SystemMessageContent] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
