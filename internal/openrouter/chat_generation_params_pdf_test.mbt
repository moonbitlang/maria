///|
test "ChatGenerationParamsPdf/roundtrip" {
  let original : Array[Json] = [
    {},
    { "engine": "native" },
    { "engine": "pdf_text" },
  ]
  let converted : Array[@openrouter.ChatGenerationParamsPdf] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
