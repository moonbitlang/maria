///|
test "ChatGenerationParamsRoute/roundtrip" {
  let original : Array[Json] = ["fallback", "sort"]
  let converted : Array[@openrouter.ChatGenerationParamsRoute] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
