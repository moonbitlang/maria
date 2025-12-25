///|
test "ChatGenerationParamsPluginModeration/roundtrip" {
  let original : Array[Json] = [{ "type": "moderation", "id": "moderation" }]
  let converted : Array[
    @chat_generation_params.ChatGenerationParamsPluginModeration,
  ] = @test_utils.from_json_array(original)
  assert_eq(@test_utils.to_json_array(converted), original)
}
