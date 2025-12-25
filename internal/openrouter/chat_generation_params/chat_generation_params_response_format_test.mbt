///|
test "ChatGenerationParamsResponseFormat/roundtrip" {
  let original : Array[Json] = [
    "text",
    "json_object",
    "python",
    { "type": "json_schema", "json_schema": "{}" },
    { "type": "text_grammar", "grammar": "root ::= \"hi\"" },
  ]
  let converted : Array[@chat_generation_params.ChatGenerationParamsResponseFormat] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
