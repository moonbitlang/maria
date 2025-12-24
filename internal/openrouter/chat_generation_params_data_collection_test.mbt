///|
test "ChatGenerationParamsDataCollection/roundtrip" {
  let original : Array[Json] = ["deny", "allow"]
  let converted : Array[@openrouter.ChatGenerationParamsDataCollection] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
