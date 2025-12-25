///|
test "Quantizations/roundtrip" {
  let original : Array[Json] = ["int4", "int8", "fp16", "fp32"]
  let converted : Array[@chat_generation_params.Quantizations] = @test_utils.from_json_array(original)
  assert_eq(@test_utils.to_json_array(converted), original)
}
