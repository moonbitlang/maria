///|
test "Debug/roundtrip" {
  let original : Array[Json] = [
    {},
    { "echo_upstream_body": true },
    { "echo_upstream_body": false },
  ]
  let converted : Array[@openrouter.Debug] = from_json_array(original)
  assert_eq(to_json_array(converted), original)
}
