///|
test "ChatGenerationParamsPdfEngine/roundtrip" {
  let original : Array[Json] = ["mistral_ocr", "pdf_text", "native"]
  let converted : Array[@chat_generation_params.ChatGenerationParamsPdfEngine] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
