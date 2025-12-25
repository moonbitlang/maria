///|
test "ChatGenerationParamsPluginWeb/roundtrip" {
  let original : Array[Json] = [
    { "type": "web", "id": "web" },
    { "type": "web", "id": "web", "max_results": 2, "engine": "exa" },
  ]
  let converted : Array[@chat_generation_params.ChatGenerationParamsPluginWeb] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
