///|
test "SystemMessage/roundtrip" {
  let original : Array[Json] = [
    { "role": "system", "content": "Hello, world!" },
    { "role": "system", "name": "test_system", "content": "Hello, world!" },
  ]
  let converted : Array[@openrouter.SystemMessage] = from_json_array(original)
  assert_eq(to_json_array(converted), original)
}
