///|
test "Sort/roundtrip" {
  let original : Array[Json] = ["price", "throughput", "latency"]
  let converted : Array[@chat_generation_params.Sort] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
