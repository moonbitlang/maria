///|
test "Message/roundtrip" {
  let original : Array[Json] = [
    { "role": "system", "content": "System message" },
    { "role": "user", "content": "User message" },
    { "role": "assistant", "content": "Assistant message" },
    { "role": "developer", "content": "Developer message" },
    { "role": "tool", "tool_call_id": "call_1", "content": "Tool response" },
    {
      "role": "assistant",
      "name": "assistant_name",
      "content": "With name",
      "tool_calls": [
        {
          "type": "function",
          "function": { "name": "my_tool", "arguments": "{}" },
        },
      ],
    },
    {
      "role": "assistant",
      "content": [
        { "type": "text", "text": "Item 1" },
        { "type": "text", "text": "Item 2" },
      ],
    },
  ]
  let converted : Array[@message.Message] = @test_utils.from_json_array(original)
  assert_eq(@test_utils.to_json_array(converted), original)
}
