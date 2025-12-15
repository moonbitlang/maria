///|
struct ChatMessageTokenLogprob {
  token : String
  logprob : Float
  bytes : Bytes
  top_logprobs : Array[ChatMessageTokenLogprob]?
}
