///|
test "ChatGenerationParamsPluginResponseHealing/roundtrip" {
  let original : Array[Json] = [
    { "type": "response-healing", "id": "response-healing" },
    { "type": "response-healing", "id": "response-healing", "enabled": true },
  ]
  let converted : Array[@openrouter.ChatGenerationParamsPluginResponseHealing] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
