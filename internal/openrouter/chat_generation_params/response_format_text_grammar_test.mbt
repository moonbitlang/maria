///|
test "ResponseFormatTextGrammar/roundtrip" {
  let original : Array[Json] = [
    { "type": "text_grammar", "grammar": "root ::= \"hi\"" },
  ]
  let converted : Array[@chat_generation_params.ResponseFormatTextGrammar] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
