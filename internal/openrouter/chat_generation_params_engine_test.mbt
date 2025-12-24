///|
test "ChatGenerationParamsEngine/roundtrip" {
  let original : Array[Json] = ["native", "exa"]
  let converted : Array[@openrouter.ChatGenerationParamsEngine] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
