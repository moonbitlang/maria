///|
pub struct TopProviderInfo {
  context_length : Int?
  max_completion_tokens : Int?
  is_moderated : Bool
} derive(ToJson)

///|
pub impl @json.FromJson for TopProviderInfo with from_json(
  json : Json,
  path : @json.JsonPath,
) -> TopProviderInfo raise @json.JsonDecodeError {
  guard json is @json.Object(json) else {
    raise @json.JsonDecodeError(
      (path, "\{PackageName}.TopProvider::from_json: expected object"),
    )
  }
  let context_length : Int? = match json.get("context_length") {
    Some(Null) => None
    Some(context_length_json) =>
      Some(
        @json.from_json(
          context_length_json,
          path=path.add_key("context_length"),
        ),
      )
    None => None
  }
  let max_completion_tokens : Int? = match json.get("max_completion_tokens") {
    Some(Null) => None
    Some(max_completion_tokens_json) =>
      Some(
        @json.from_json(
          max_completion_tokens_json,
          path=path.add_key("max_completion_tokens"),
        ),
      )
    None => None
  }
  let is_moderated : Bool = {
    guard json.get("is_moderated") is Some(is_moderated_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("is_moderated"),
          "\{PackageName}.TopProvider::from_json: missing field is_moderated",
        ),
      )
    }
    @json.from_json(is_moderated_json, path=path.add_key("is_moderated"))
  }
  TopProviderInfo::{ context_length, max_completion_tokens, is_moderated }
}
