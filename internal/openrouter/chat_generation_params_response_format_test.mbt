///|
test "ChatGenerationParamsResponseFormat/roundtrip" {
  let original : Array[Json] = [
    "text",
    "json_object",
    "python",
    { "type": "json_schema", "json_schema": "{}" },
    { "type": "text_grammar", "grammar": "root ::= \"hi\"" },
  ]
  let converted : Array[@openrouter.ChatGenerationParamsResponseFormat] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
