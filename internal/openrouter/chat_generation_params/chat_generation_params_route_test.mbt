///|
test "ChatGenerationParamsRoute/roundtrip" {
  let original : Array[Json] = ["fallback", "sort"]
  let converted : Array[@chat_generation_params.ChatGenerationParamsRoute] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
