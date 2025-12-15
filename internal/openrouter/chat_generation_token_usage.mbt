///|
struct ChatGenerationTokenUsage {
  completion_tokens : Int
  prompt_tokens : Int
  total_tokens : Int
  completion_tokens_details : CompletionTokensDetails?
  prompt_tokens_details : PromptTokensDetails?
}
