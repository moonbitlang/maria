///|
test "impl ToJson for Conversation" {
  let conversation = Conversation::new(id=Id::new(), name="Test Conversation")
  conversation.add_message(@openai.user_message(content="Hello"))
  @json.inspect(conversation |> @mock.strip_uuid() |> @mock.strip_timestamp(), content={
    "name": "Test Conversation",
    "id": "...",
    "messages": [
      { "timestamp": "...", "message": { "role": "user", "content": "Hello" } },
    ],
    "created_at": "...",
    "updated_at": "...",
  })
}
