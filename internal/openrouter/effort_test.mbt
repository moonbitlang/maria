///|
test "Effort/roundtrip" {
  let original : Array[Json] = ["none", "low", "medium", "high"]
  let converted : Array[@openrouter.Effort] = from_json_array(original)
  assert_eq(to_json_array(converted), original)
}
