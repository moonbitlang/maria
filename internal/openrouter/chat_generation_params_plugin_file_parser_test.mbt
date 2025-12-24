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
  let converted : Array[@openrouter.ChatGenerationParamsPluginFileParser] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
