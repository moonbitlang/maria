///|
test "ChatGenerationParamsPdf/roundtrip" {
  let original : Array[Json] = [
    {},
    { "engine": "native" },
    { "engine": "pdf_text" },
  ]
  let converted : Array[@chat_generation_params.ChatGenerationParamsPdf] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
