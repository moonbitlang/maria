///|
test "ReasoningSummaryVerbosity/roundtrip" {
  let original : Array[Json] = ["disabled", "low", "medium", "high"]
  let converted : Array[@chat_generation_params.ReasoningSummaryVerbosity] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
