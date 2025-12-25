///|
test "ChatGenerationParamsPluginFileParser/roundtrip" {
  let original : Array[Json] = [
    { "type": "file_parser", "id": "file-parser" },
    {
      "type": "file_parser",
      "id": "file-parser",
      "enabled": true,
      "max_files": 3,
      "pdf": { "engine": "native" },
    },
  ]
  let converted : Array[
    @chat_generation_params.ChatGenerationParamsPluginFileParser,
  ] = @test_utils.from_json_array(original)
  assert_eq(@test_utils.to_json_array(converted), original)
}
