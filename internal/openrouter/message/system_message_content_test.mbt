///|
test "SystemMessageContent/roundtrip" {
  let original : Array[Json] = [
    "Hello, system!",
    [{ "type": "text", "text": "Item 1" }],
  ]
  let converted : Array[@message.SystemMessageContent] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
