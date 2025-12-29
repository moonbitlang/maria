///|
/// Truncation strategy used for the model response.
pub enum ResponseTruncation {
  Auto
  Disabled
}

///|
pub impl ToJson for ResponseTruncation with to_json(self : ResponseTruncation) -> Json {
  match self {
    Auto => "auto"
    Disabled => "disabled"
  }
}

///|
pub impl @json.FromJson for ResponseTruncation with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseTruncation raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError((path, "ResponseTruncation: expected string"))
  }
  match value {
    "auto" => Auto
    "disabled" => Disabled
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseTruncation: invalid value '\{value}'"),
      )
  }
}
