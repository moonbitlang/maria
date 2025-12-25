///|
test "ChatMessageContentItemCacheControlEphemeral/roundtrip" {
  let original : Array[Json] = [
    { "type": "ephemeral" },
    { "type": "ephemeral", "ttl": "5m" },
    { "type": "ephemeral", "ttl": "1h" },
  ]
  let converted : Array[@message.ChatMessageContentItemCacheControlEphemeral] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
