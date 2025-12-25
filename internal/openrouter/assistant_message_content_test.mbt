///|
test "AssistantMessageContent/roundtrip" {
  let original : Array[Json] = [
    "Hello, assistant!",
    [{ "type": "text", "text": "Item 1" }, { "type": "text", "text": "Item 2" }],
  ]
  let converted : Array[@message.AssistantMessageContent] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
