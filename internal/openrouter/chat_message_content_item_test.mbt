///|
test "ChatMessageContentItem/roundtrip" {
  let original : Array[Json] = [
    { "type": "text", "text": "Item 1" },
    {
      "type": "text",
      "text": "Item 1",
      "cache_control": { "type": "ephemeral" },
    },
    {
      "type": "text",
      "text": "Item 1",
      "cache_control": { "type": "ephemeral", "ttl": "5m" },
    },
  ]
  let converted : Array[@message.ChatMessageContentItem] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
