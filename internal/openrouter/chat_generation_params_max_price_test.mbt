///|
test "ChatGenerationParamsMaxPrice/roundtrip" {
  let original : Array[Json] = [
    {},
    { "prompt": "1" },
    { "completion": "2", "request": "3" },
    { "image": "4", "audio": "5", "prompt": "6", "completion": "7" },
  ]
  let converted : Array[@openrouter.ChatGenerationParamsMaxPrice] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
