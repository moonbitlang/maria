///|
struct ChatMessageTokenLogprob {
  token : String
  logprob : Float
  bytes : Bytes
  top_logprobs : Array[ChatMessageTokenLogprob]?
}

///|
pub impl ToJson for ChatMessageTokenLogprob with to_json(
  self : ChatMessageTokenLogprob,
) -> Json {
  let object : Map[String, Json] = {
    "token": self.token.to_json(),
    "logprob": self.logprob.to_json(),
    "bytes": self.bytes.to_json(),
  }
  if self.top_logprobs is Some(top_logprobs) {
    object["top_logprobs"] = top_logprobs.to_json()
  }
  Json::object(object)
}
