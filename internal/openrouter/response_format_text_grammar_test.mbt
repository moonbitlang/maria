///|
test "ResponseFormatTextGrammar/roundtrip" {
  let original : Array[Json] = [
    { "type": "text_grammar", "grammar": "root ::= \"hi\"" },
  ]
  let converted : Array[@openrouter.ResponseFormatTextGrammar] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
