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
  let converted : Array[@message.UserMessage] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
