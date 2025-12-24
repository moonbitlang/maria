///|
test "ReasoningSummaryVerbosity/roundtrip" {
  let original : Array[Json] = ["disabled", "low", "medium", "high"]
  let converted : Array[@openrouter.ReasoningSummaryVerbosity] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
