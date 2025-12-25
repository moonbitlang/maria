///|
test "Debug/roundtrip" {
  let original : Array[Json] = [
    {},
    { "echo_upstream_body": true },
    { "echo_upstream_body": false },
  ]
  let converted : Array[@chat_generation_params.Debug] = @test_utils.from_json_array(original)
  assert_eq(@test_utils.to_json_array(converted), original)
}
