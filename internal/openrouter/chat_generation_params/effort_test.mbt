///|
test "Effort/roundtrip" {
  let original : Array[Json] = ["none", "low", "medium", "high"]
  let converted : Array[@chat_generation_params.Effort] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
