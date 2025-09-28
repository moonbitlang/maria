///|
test "impl ToJson for Conversation" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  let conversation = Conversation::new(
    id=Id::new(rand~),
    name="Test Conversation",
  )
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
