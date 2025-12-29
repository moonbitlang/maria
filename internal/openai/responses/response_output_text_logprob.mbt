///|
/// The log probability of a token.
struct ResponseOutputTextLogprob {
  /// The token.
  token : String
  /// The byte representation of the token.
  bytes : Array[Int64]
  /// The log probability of the token.
  logprob : Double
  /// The top log probabilities for this token.
  top_logprobs : Array[ResponseOutputTextLogprobTopLogprob]
}

///|
pub impl ToJson for ResponseOutputTextLogprob with to_json(
  self : ResponseOutputTextLogprob,
) -> Json {
  {
    "token": self.token,
    "bytes": self.bytes,
    "logprob": self.logprob,
    "top_logprobs": self.top_logprobs,
  }
}

///|
pub impl @json.FromJson for ResponseOutputTextLogprob with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputTextLogprob raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let token : String = object.required("token", path~)
  let bytes : Array[Int64] = object.required("bytes", path~)
  let logprob : Double = object.required("logprob", path~)
  let top_logprobs : Array[ResponseOutputTextLogprobTopLogprob] = object.required(
    "top_logprobs",
    path~,
  )
  ResponseOutputTextLogprob::{ token, bytes, logprob, top_logprobs }
}
