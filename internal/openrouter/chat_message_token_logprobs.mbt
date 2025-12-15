///|
struct ChatMessageTokenLogprobs {
  tokens : Array[String]
  logprobs : Array[Float]
  bytes : Bytes?
  top_logprobs : Array[TopLogprob]
}

///|
pub impl ToJson for ChatMessageTokenLogprobs with to_json(
  self : ChatMessageTokenLogprobs,
) -> Json {
  let object : Map[String, Json] = {
    "tokens": self.tokens.to_json(),
    "logprobs": self.logprobs.to_json(),
    "top_logprobs": self.top_logprobs.to_json(),
  }
  if self.bytes is Some(bytes) {
    object["bytes"] = bytes.to_json()
  }
  Json::object(object)
}
