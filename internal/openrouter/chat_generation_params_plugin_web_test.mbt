///|
test "ChatGenerationParamsPluginWeb/roundtrip" {
  let original : Array[Json] = [
    { "type": "web", "id": "web" },
    { "type": "web", "id": "web", "max_results": 2, "engine": "exa" },
  ]
  let converted : Array[@openrouter.ChatGenerationParamsPluginWeb] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
