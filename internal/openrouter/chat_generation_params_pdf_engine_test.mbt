///|
test "ChatGenerationParamsPdfEngine/roundtrip" {
  let original : Array[Json] = ["mistral_ocr", "pdf_text", "native"]
  let converted : Array[@openrouter.ChatGenerationParamsPdfEngine] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
