///|
/// Token usage details for a response.
pub struct ResponseUsage {
  input_tokens : Int64
  input_tokens_details : ResponseUsageInputTokensDetails
  output_tokens : Int64
  output_tokens_details : ResponseUsageOutputTokensDetails
  total_tokens : Int64
}

///|
/// Detailed breakdown of input tokens.
pub struct ResponseUsageInputTokensDetails {
  cached_tokens : Int64
}

///|
/// Detailed breakdown of output tokens.
pub struct ResponseUsageOutputTokensDetails {
  reasoning_tokens : Int64
}

///|
pub impl ToJson for ResponseUsageInputTokensDetails with to_json(
  self : ResponseUsageInputTokensDetails,
) -> Json {
  { "cached_tokens": @jsonx.int64(self.cached_tokens) }
}

///|
pub impl @json.FromJson for ResponseUsageInputTokensDetails with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseUsageInputTokensDetails raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let cached_tokens = object.required_int64("cached_tokens", path~)
  ResponseUsageInputTokensDetails::{ cached_tokens, }
}

///|
pub impl ToJson for ResponseUsageOutputTokensDetails with to_json(
  self : ResponseUsageOutputTokensDetails,
) -> Json {
  { "reasoning_tokens": @jsonx.int64(self.reasoning_tokens) }
}

///|
pub impl @json.FromJson for ResponseUsageOutputTokensDetails with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseUsageOutputTokensDetails raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let reasoning_tokens = object.required_int64("reasoning_tokens", path~)
  ResponseUsageOutputTokensDetails::{ reasoning_tokens, }
}

///|
pub impl ToJson for ResponseUsage with to_json(self : ResponseUsage) -> Json {
  {
    "input_tokens": @jsonx.int64(self.input_tokens),
    "input_tokens_details": self.input_tokens_details,
    "output_tokens": @jsonx.int64(self.output_tokens),
    "output_tokens_details": self.output_tokens_details,
    "total_tokens": @jsonx.int64(self.total_tokens),
  }
}

///|
pub impl @json.FromJson for ResponseUsage with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseUsage raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let input_tokens = object.required_int64("input_tokens", path~)
  let input_tokens_details : ResponseUsageInputTokensDetails = object.required(
    "input_tokens_details",
    path~,
  )
  let output_tokens = object.required_int64("output_tokens", path~)
  let output_tokens_details : ResponseUsageOutputTokensDetails = object.required(
    "output_tokens_details",
    path~,
  )
  let total_tokens = object.required_int64("total_tokens", path~)
  ResponseUsage::{
    input_tokens,
    input_tokens_details,
    output_tokens,
    output_tokens_details,
    total_tokens,
  }
}
