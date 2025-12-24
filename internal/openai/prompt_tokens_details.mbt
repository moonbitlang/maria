///|
/// Token usage details for the prompt segment.
pub struct PromptTokensDetails {
  cached_tokens : Int?
  audio_tokens : Int?
} derive(Show, ToJson)

///|
pub fn PromptTokensDetails::new(
  cached_tokens? : Int,
  audio_tokens? : Int,
) -> PromptTokensDetails {
  { cached_tokens, audio_tokens }
}

///|
impl @json.FromJson for PromptTokensDetails with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> PromptTokensDetails {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let cached_tokens = match json.get("cached_tokens") {
    Some(Null) => None
    Some(Number(cached_tokens, ..)) => Some(cached_tokens.to_int())
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'cached_tokens' to be a number"),
      )
    None => None
  }
  let audio_tokens = match json.get("audio_tokens") {
    Some(Null) => None
    Some(Number(audio_tokens, ..)) => Some(audio_tokens.to_int())
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'audio_tokens' to be a number"),
      )
    None => None
  }
  PromptTokensDetails::{ cached_tokens, audio_tokens }
}
