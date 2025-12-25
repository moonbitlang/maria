///|
test "ChatGenerationParamsDataCollection/roundtrip" {
  let original : Array[Json] = ["deny", "allow"]
  let converted : Array[@chat_generation_params.ChatGenerationParamsDataCollection] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
