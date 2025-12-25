///|
test "Ttl/roundtrip" {
  let original : Array[Json] = ["5m", "1h"]
  let converted : Array[@chat_message.Ttl] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
