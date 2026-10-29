///|
/// Token usage details for the model-completion segment.
pub struct CompletionTokensDetails {
  reasoning_tokens : Int32?
} derive(Debug, ToJson)

///|
impl @json.FromJson for CompletionTokensDetails with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> CompletionTokensDetails {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let reasoning_tokens = match json.get("reasoning_tokens") {
    Some(Null) => None
    Some(Number(reasoning_tokens, ..)) => Some(reasoning_tokens.to_int())
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'reasoning_tokens' to be a number"),
      )
    None => None
  }
  CompletionTokensDetails::{ reasoning_tokens, }
}

///|
pub extend CompletionTokensDetails with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CompletionTokensDetails with ToJson::{to_json}
