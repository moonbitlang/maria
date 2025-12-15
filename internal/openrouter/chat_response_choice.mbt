///|
struct ChatResponseChoice {
  finish_reason : ChatCompletionFinishReason?
  index : Int
  message : AssistantMessage
  logprobs : ChatMessageTokenLogprobs?
}
