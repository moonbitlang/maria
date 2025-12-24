///|
test "Quantizations/roundtrip" {
  let original : Array[Json] = ["int4", "int8", "fp16", "fp32"]
  let converted : Array[@openrouter.Quantizations] = from_json_array(original)
  assert_eq(to_json_array(converted), original)
}
