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

///|
pub impl @json.FromJson for TopLogprob with from_json(
  json : Json,
  path : @json.JsonPath,
) -> TopLogprob raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.TopLogprob::from_json"
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
  let bytes : Bytes? = match object.get("bytes") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("bytes")))
  }
  TopLogprob::{ token, logprob, bytes }
}
