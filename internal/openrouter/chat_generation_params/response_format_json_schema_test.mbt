///|
test "ResponseFormatJSONSchema/roundtrip" {
  let original : Array[Json] = [
    { "type": "json_schema", "json_schema": "{}" },
    { "type": "json_schema", "json_schema": "{\"name\":\"x\"}" },
  ]
  let converted : Array[@chat_generation_params.ResponseFormatJSONSchema] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
