///|
test "MessageDeveloper/roundtrip" {
  let original : Array[Json] = [
    { "role": "developer", "content": "Hello, world!" },
    {
      "role": "developer",
      "name": "test_developer",
      "content": "Hello, world!",
    },
  ]
  let converted : Array[@message.MessageDeveloper] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
