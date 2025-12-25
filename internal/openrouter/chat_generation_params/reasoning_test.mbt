///|
test "Reasoning/roundtrip" {
  let original : Array[Json] = [
    {},
    { "effort": "low" },
    { "summary": "high" },
    { "effort": "medium", "summary": "low" },
  ]
  let converted : Array[@chat_generation_params.Reasoning] = @test_utils.from_json_array(original)
  assert_eq(@test_utils.to_json_array(converted), original)
}
