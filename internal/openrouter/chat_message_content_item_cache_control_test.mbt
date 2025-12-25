///|
test "ChatMessageContentItemCacheControl/roundtrip" {
  let original : Array[Json] = [
    { "type": "ephemeral" },
    { "type": "ephemeral", "ttl": "5m" },
  ]
  let converted : Array[@message.ChatMessageContentItemCacheControl] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
