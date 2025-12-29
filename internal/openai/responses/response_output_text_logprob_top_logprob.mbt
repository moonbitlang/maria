///|
/// The top log probability of a token.
struct ResponseOutputTextLogprobTopLogprob {
  /// The token.
  token : String
  /// The byte representation of the token.
  bytes : Bytes
  /// The log probability of the token.
  logprob : Double
}

///|
pub impl ToJson for ResponseOutputTextLogprobTopLogprob with to_json(
  self : ResponseOutputTextLogprobTopLogprob,
) -> Json {
  {
    "token": self.token,
    "bytes": self.bytes.to_array().map((b : Byte) => b.to_int()),
    "logprob": self.logprob,
  }
}

///|
pub impl @json.FromJson for ResponseOutputTextLogprobTopLogprob with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputTextLogprobTopLogprob raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let token : String = object.required("token", path~)
  let bytes : Array[Int] = object.required("bytes", path~)
  let bytes : Bytes = Bytes::from_array(bytes.map((b : Int) => b.to_byte()))
  let logprob : Double = object.required("logprob", path~)
  ResponseOutputTextLogprobTopLogprob::{ token, bytes, logprob }
}
