///|
test "ChatResponse/roundtrip" {
  let original : Array[Json] = [
    {
      "id": "resp_1",
      "model": "openai/gpt-4o-mini",
      "created": 123,
      "object": "chat.completion",
      "choices": [
        {
          "index": 0,
          "message": { "role": "assistant", "content": "Hello" },
          "finish_reason": "stop",
        },
      ],
    },
    {
      "id": "resp_2",
      "model": "openai/gpt-4o-mini",
      "created": 123,
      "object": "chat.completion",
      "choices": [
        { "index": 0, "message": { "role": "assistant", "content": "Hello" } },
      ],
      "usage": {
        "prompt_tokens": 1,
        "completion_tokens": 2,
        "total_tokens": 3,
        "prompt_tokens_details": { "cached_tokens": 1 },
        "completion_tokens_details": { "reasoning_tokens": 2 },
      },
    },
  ]
  let converted : Array[@openrouter.ChatResponse] = @test_utils.from_json_array(
    original,
  )
  assert_eq(@test_utils.to_json_array(converted), original)
}
