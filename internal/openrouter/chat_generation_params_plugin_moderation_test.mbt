///|
test "ChatGenerationParamsPluginModeration/roundtrip" {
  let original : Array[Json] = [{ "type": "moderation", "id": "moderation" }]
  let converted : Array[@openrouter.ChatGenerationParamsPluginModeration] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
