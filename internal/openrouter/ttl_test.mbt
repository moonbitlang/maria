///|
test "Ttl/roundtrip" {
  let original : Array[Json] = ["5m", "1h"]
  let converted : Array[@message.Ttl] = from_json_array(original)
  assert_eq(to_json_array(converted), original)
}
