///|
test "ChatMessageContentItemCacheControl/roundtrip" {
  let original : Array[Json] = [
    { "type": "ephemeral" },
    { "type": "ephemeral", "ttl": "5m" },
  ]
  let converted : Array[@chat_message.ChatMessageContentItemCacheControl] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
