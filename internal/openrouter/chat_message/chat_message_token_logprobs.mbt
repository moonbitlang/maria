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

///|
pub impl @json.FromJson for ChatMessageTokenLogprobs with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatMessageTokenLogprobs raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatMessageTokenLogprobs::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let tokens : Array[String] = match object.get("tokens") {
    Some(v) => @json.from_json(v, path=path.add_key("tokens"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("tokens"), "\{func_name}: missing field tokens"),
      )
  }
  let logprobs : Array[Float] = match object.get("logprobs") {
    Some(v) => @json.from_json(v, path=path.add_key("logprobs"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("logprobs"), "\{func_name}: missing field logprobs"),
      )
  }
  let top_logprobs : Array[TopLogprob] = match object.get("top_logprobs") {
    Some(v) => @json.from_json(v, path=path.add_key("top_logprobs"))
    None =>
      raise @json.JsonDecodeError(
        (
          path.add_key("top_logprobs"),
          "\{func_name}: missing field top_logprobs",
        ),
      )
  }
  let bytes : Bytes? = match object.get("bytes") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("bytes")))
  }
  ChatMessageTokenLogprobs::{ tokens, logprobs, bytes, top_logprobs }
}
