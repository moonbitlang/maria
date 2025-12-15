///|
struct CompletionTokensDetails {
  reasoning_tokens : Int?
  audio_tokens : Int?
  accepted_prediction_tokens : Int?
  rejected_prediction_tokens : Int?
}

///|
pub impl ToJson for CompletionTokensDetails with to_json(
  self : CompletionTokensDetails,
) -> Json {
  let object : Map[String, Json] = {}
  if self.reasoning_tokens is Some(reasoning_tokens) {
    object["reasoning_tokens"] = reasoning_tokens.to_json()
  }
  if self.audio_tokens is Some(audio_tokens) {
    object["audio_tokens"] = audio_tokens.to_json()
  }
  if self.accepted_prediction_tokens is Some(accepted_prediction_tokens) {
    object["accepted_prediction_tokens"] = accepted_prediction_tokens.to_json()
  }
  if self.rejected_prediction_tokens is Some(rejected_prediction_tokens) {
    object["rejected_prediction_tokens"] = rejected_prediction_tokens.to_json()
  }
  Json::object(object)
}
