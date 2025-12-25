///|
struct ChatMessageTokenLogprob {
  token : String
  logprob : Float
  bytes : Bytes
  top_logprobs : Array[TopLogprob]?
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

///|
pub impl @json.FromJson for ChatMessageTokenLogprob with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatMessageTokenLogprob raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatMessageTokenLogprob::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let token : String = match object.get("token") {
    Some(v) => @json.from_json(v, path=path.add_key("token"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("token"), "\{func_name}: missing field token"),
      )
  }
  let logprob : Float = match object.get("logprob") {
    Some(v) => @json.from_json(v, path=path.add_key("logprob"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("logprob"), "\{func_name}: missing field logprob"),
      )
  }
  let bytes : Bytes = match object.get("bytes") {
    Some(v) => @json.from_json(v, path=path.add_key("bytes"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("bytes"), "\{func_name}: missing field bytes"),
      )
  }
  let top_logprobs : Array[TopLogprob]? = match
    object.get("top_logprobs") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("top_logprobs")))
  }
  ChatMessageTokenLogprob::{ token, logprob, bytes, top_logprobs }
}
