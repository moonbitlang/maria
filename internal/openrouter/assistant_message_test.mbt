///|
test "AssistantMessage/roundtrip" {
  let original : Array[Json] = [
    { "role": "assistant", "content": "Hello, world!" },
    {
      "role": "assistant",
      "name": "test_assistant",
      "content": "Hello, world!",
    },
    {
      "role": "assistant",
      "content": "Hello, world!",
      "tool_calls": [
        {
          "type": "function",
          "function": { "name": "my_tool", "arguments": "{}" },
        },
      ],
    },
  ]
  let converted : Array[@message.AssistantMessage] = from_json_array(
    original,
  )
  assert_eq(to_json_array(converted), original)
}
