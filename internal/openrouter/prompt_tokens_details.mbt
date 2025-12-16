///|
struct PromptTokensDetails {
  cached_tokens : Int?
  audio_tokens : Int?
  video_tokens : Int?
}

///|
pub impl ToJson for PromptTokensDetails with to_json(self : PromptTokensDetails) -> Json {
  let object : Map[String, Json] = {}
  if self.cached_tokens is Some(cached_tokens) {
    object["cached_tokens"] = cached_tokens.to_json()
  }
  if self.audio_tokens is Some(audio_tokens) {
    object["audio_tokens"] = audio_tokens.to_json()
  }
  if self.video_tokens is Some(video_tokens) {
    object["video_tokens"] = video_tokens.to_json()
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for PromptTokensDetails with from_json(
  json : Json,
  path : @json.JsonPath,
) -> PromptTokensDetails raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.PromptTokensDetails::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let cached_tokens : Int? = match object.get("cached_tokens") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("cached_tokens")))
  }
  let audio_tokens : Int? = match object.get("audio_tokens") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("audio_tokens")))
  }
  let video_tokens : Int? = match object.get("video_tokens") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("video_tokens")))
  }
  PromptTokensDetails::{ cached_tokens, audio_tokens, video_tokens }
}
