///|
test "ChatGenerationParamsProvider/roundtrip" {
  let original : Array[Json] = [
    {},
    { "allow_fallbacks": true, "zdr": false },
    {
      "order": [{ "value": "openai" }],
      "only": [{ "value": "anthropic" }],
      "ignore": [{ "value": "deepseek" }],
    },
    {
      "quantizations": ["int4", "fp16"],
      "sort": "price",
      "max_price": { "prompt": "1", "completion": "2" },
      "min_throughput": 1.5,
      "max_latency": 2.25,
    },
    {
      "data_collection": "deny",
      "require_parameters": true,
      "enforce_distillable_text": true,
    },
  ]
  let converted : Array[@chat_generation_params.ChatGenerationParamsProvider] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
