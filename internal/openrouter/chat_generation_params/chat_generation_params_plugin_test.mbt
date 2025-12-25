///|
test "ChatGenerationParamsPlugin/roundtrip" {
  let original : Array[Json] = [
    { "type": "moderation" },
    { "type": "web", "id": "web", "max_results": 2 },
    {
      "type": "file_parser",
      "id": "file-parser",
      "pdf": { "engine": "native" },
    },
    { "type": "response-healing", "id": "response-healing", "enabled": true },
  ]
  let converted : Array[@chat_generation_params.ChatGenerationParamsPlugin] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
