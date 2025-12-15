///|
struct AssistantMessage {
  content : AssistantMessageContent
  name : String?
  tool_calls : Array[ChatMessageToolCall]?
  refusal : String?
  reasoning : String?
}
