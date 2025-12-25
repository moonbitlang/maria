///|
test "ChatGenerationParamsEngine/roundtrip" {
  let original : Array[Json] = ["native", "exa"]
  let converted : Array[@chat_generation_params.ChatGenerationParamsEngine] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
