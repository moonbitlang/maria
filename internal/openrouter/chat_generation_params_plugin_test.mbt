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
  let converted : Array[@openrouter.ChatGenerationParamsPlugin] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
