///|
test "ChatMessageContentItemCacheControl/roundtrip" {
  let original : Array[Json] = [
    { "type": "ephemeral" },
    { "type": "ephemeral", "ttl": "5m" },
  ]
  let converted : Array[@openrouter.ChatMessageContentItemCacheControl] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
