///|
test "Sort/roundtrip" {
  let original : Array[Json] = ["price", "throughput", "latency"]
  let converted : Array[@openrouter.Sort] = from_json_array(original)
  assert_eq(to_json_array(converted), original)
}
