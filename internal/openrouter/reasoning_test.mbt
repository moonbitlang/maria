///|
test "Reasoning/roundtrip" {
  let original : Array[Json] = [
    {},
    { "effort": "low" },
    { "summary": "high" },
    { "effort": "medium", "summary": "low" },
  ]
  let converted : Array[@openrouter.Reasoning] = from_json_array(original)
  assert_eq(to_json_array(converted), original)
}
