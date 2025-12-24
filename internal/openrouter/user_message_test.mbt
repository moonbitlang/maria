///|
test "UserMessage/roundtrip" {
  let original : Array[Json] = [
    { "role": "user", "content": "Hello, world!" },
    { "role": "user", "name": "test_user", "content": "Hello, world!" },
    { "role": "user", "content": [{ "type": "text", "text": "Item 1" }] },
    {
      "role": "user",
      "name": "test_user",
      "content": [{ "type": "text", "text": "Item 1" }],
    },
  ]
  let converted : Array[@openrouter.UserMessage] = from_json_array(original)
  assert_eq(to_json_array(converted), original)
}
