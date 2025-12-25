///|
test "ChatGenerationParams/roundtrip" {
  let original : Array[Json] = [
    { "stream": false, "messages": [{ "role": "user", "content": "Hi" }] },
    {
      "stream": true,
      "messages": [{ "role": "user", "content": "Hi" }],
      "model": "openai/gpt-4o-mini",
      "temperature": 0.699999988079071,
      "top_p": 0.8999999761581421,
      "max_tokens": 32,
      "seed": 123,
      "stop": ["\n\n"],
      "response_format": {
        "type": "json_schema",
        "json_schema": "{\"name\":\"x\"}",
      },
      "stream_options": { "include_usage": true },
      "reasoning": { "effort": "low", "summary": "low" },
      "provider": { "order": [{ "value": "openai" }], "allow_fallbacks": true },
      "plugins": [
        { "type": "moderation" },
        { "type": "web", "id": "web", "max_results": 2 },
        {
          "type": "file_parser",
          "id": "file-parser",
          "pdf": { "engine": "native" },
        },
        {
          "type": "response-healing",
          "id": "response-healing",
          "enabled": true,
        },
      ],
      "route": "fallback",
    },
  ]
  let converted : Array[@chat_generation_params.ChatGenerationParams] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
