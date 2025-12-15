///|
struct ChatMessageTokenLogprobs {
  tokens : Array[String]
  logprobs : Array[Float]
  bytes : Bytes?
  top_logprobs : Array[TopLogprob]
}
