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
  let converted : Array[@message.MessageDeveloper] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
