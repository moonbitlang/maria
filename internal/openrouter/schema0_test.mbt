///|
test "Schema0/roundtrip" {
  let original : Array[Json] = [{ "value": "openai" }, { "value": "anthropic" }]
  let converted : Array[@openrouter.Schema0] = from_json_array(original)
  assert_eq(to_json_array(converted), original)
}
