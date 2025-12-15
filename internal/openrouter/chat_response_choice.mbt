///|
struct ChatResponseChoice {
  finish_reason : ChatCompletionFinishReason?
  index : Int
  message : AssistantMessage
  logprobs : ChatMessageTokenLogprobs?
}

///|
pub impl ToJson for ChatResponseChoice with to_json(self : ChatResponseChoice) -> Json {
  let object : Map[String, Json] = { "index": self.index.to_json() }
  if self.finish_reason is Some(finish_reason) {
    object["finish_reason"] = finish_reason.to_json()
  }
  object["message"] = self.message.to_json()
  if self.logprobs is Some(logprobs) {
    object["logprobs"] = logprobs.to_json()
  }
  Json::object(object)
}
