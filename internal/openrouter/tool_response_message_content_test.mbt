///|
test "ToolResponseMessageContent/roundtrip" {
  let original : Array[Json] = [
    "Tool output",
    [{ "type": "text", "text": "Item 1" }, { "type": "text", "text": "Item 2" }],
  ]
  let converted : Array[@message.ToolResponseMessageContent] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
