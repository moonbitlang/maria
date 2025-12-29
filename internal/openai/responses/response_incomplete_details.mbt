///|
/// Details about why the response is incomplete.
pub struct ResponseIncompleteDetails {
  reason : ResponseIncompleteReason
}

///|
pub enum ResponseIncompleteReason {
  MaxOutputTokens
  ContentFilter
}

///|
pub impl ToJson for ResponseIncompleteReason with to_json(
  self : ResponseIncompleteReason,
) -> Json {
  match self {
    MaxOutputTokens => "max_output_tokens"
    ContentFilter => "content_filter"
  }
}

///|
pub impl @json.FromJson for ResponseIncompleteReason with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseIncompleteReason raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError(
      (path, "ResponseIncompleteReason: expected string"),
    )
  }
  match value {
    "max_output_tokens" => MaxOutputTokens
    "content_filter" => ContentFilter
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseIncompleteReason: invalid value '\{value}'"),
      )
  }
}

///|
pub impl ToJson for ResponseIncompleteDetails with to_json(
  self : ResponseIncompleteDetails,
) -> Json {
  { "reason": self.reason }
}

///|
pub impl @json.FromJson for ResponseIncompleteDetails with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseIncompleteDetails raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let reason : ResponseIncompleteReason = object.required("reason", path~)
  ResponseIncompleteDetails::{ reason, }
}
