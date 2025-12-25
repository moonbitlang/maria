///|
test "ChatGenerationParamsPluginResponseHealing/roundtrip" {
  let original : Array[Json] = [
    { "type": "response-healing", "id": "response-healing" },
    { "type": "response-healing", "id": "response-healing", "enabled": true },
  ]
  let converted : Array[
    @chat_generation_params.ChatGenerationParamsPluginResponseHealing,
  ] = @test_utils.from_json_array(original)
  assert_eq(@test_utils.to_json_array(converted), original)
}
