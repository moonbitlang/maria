///|
struct ChatGenerationTokenUsage {
  completion_tokens : Int
  prompt_tokens : Int
  total_tokens : Int
  completion_tokens_details : CompletionTokensDetails?
  prompt_tokens_details : PromptTokensDetails?
}

///|
pub impl ToJson for ChatGenerationTokenUsage with to_json(
  self : ChatGenerationTokenUsage,
) -> Json {
  let object : Map[String, Json] = {
    "completion_tokens": self.completion_tokens.to_json(),
    "prompt_tokens": self.prompt_tokens.to_json(),
    "total_tokens": self.total_tokens.to_json(),
  }
  if self.completion_tokens_details is Some(completion_tokens_details) {
    object["completion_tokens_details"] = completion_tokens_details.to_json()
  }
  if self.prompt_tokens_details is Some(prompt_tokens_details) {
    object["prompt_tokens_details"] = prompt_tokens_details.to_json()
  }
  Json::object(object)
}
