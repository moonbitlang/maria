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
