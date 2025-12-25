///|
test "ChatMessageContentItemCacheControlEphemeral/roundtrip" {
  let original : Array[Json] = [
    { "type": "ephemeral" },
    { "type": "ephemeral", "ttl": "5m" },
    { "type": "ephemeral", "ttl": "1h" },
  ]
  let converted : Array[
    @chat_message.ChatMessageContentItemCacheControlEphemeral,
  ] = @test_utils.from_json_array(original)
  assert_eq(@test_utils.to_json_array(converted), original)
}
