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

///|
pub impl @json.FromJson for CompletionTokensDetails with from_json(
  json : Json,
  path : @json.JsonPath,
) -> CompletionTokensDetails raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.CompletionTokensDetails::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let reasoning_tokens : Int? = match object.get("reasoning_tokens") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("reasoning_tokens")))
  }
  let audio_tokens : Int? = match object.get("audio_tokens") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("audio_tokens")))
  }
  let accepted_prediction_tokens : Int? = match
    object.get("accepted_prediction_tokens") {
    None | Some(Null) => None
    Some(v) =>
      Some(@json.from_json(v, path=path.add_key("accepted_prediction_tokens")))
  }
  let rejected_prediction_tokens : Int? = match
    object.get("rejected_prediction_tokens") {
    None | Some(Null) => None
    Some(v) =>
      Some(@json.from_json(v, path=path.add_key("rejected_prediction_tokens")))
  }
  CompletionTokensDetails::{
    reasoning_tokens,
    audio_tokens,
    accepted_prediction_tokens,
    rejected_prediction_tokens,
  }
}
