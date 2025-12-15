///|
struct TopLogprob {
  token : String
  logprob : Float
  bytes : Bytes?
}

///|
pub impl ToJson for TopLogprob with to_json(self : TopLogprob) -> Json {
  let object : Map[String, Json] = {
    "token": self.token.to_json(),
    "logprob": self.logprob.to_json(),
  }
  if self.bytes is Some(bytes) {
    object["bytes"] = bytes.to_json()
  }
  Json::object(object)
}
