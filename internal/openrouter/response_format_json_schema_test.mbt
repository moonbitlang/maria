///|
test "ResponseFormatJSONSchema/roundtrip" {
  let original : Array[Json] = [
    { "type": "json_schema", "json_schema": "{}" },
    { "type": "json_schema", "json_schema": "{\"name\":\"x\"}" },
  ]
  let converted : Array[@openrouter.ResponseFormatJSONSchema] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
