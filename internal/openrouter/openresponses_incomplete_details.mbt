///|
enum OpenResponsesIncompleteReason {
  MaxOutputTokens
  ContentFilter
}

///|
pub impl ToJson for OpenResponsesIncompleteReason with to_json(
  self : OpenResponsesIncompleteReason,
) -> Json {
  match self {
    MaxOutputTokens => "max_output_tokens"
    ContentFilter => "content_filter"
  }
}

///|
pub impl @json.FromJson for OpenResponsesIncompleteReason with from_json(
  json : Json,
  path : @json.JsonPath,
) -> OpenResponsesIncompleteReason raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.OpenResponsesIncompleteReason::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "max_output_tokens" => OpenResponsesIncompleteReason::MaxOutputTokens
    "content_filter" => OpenResponsesIncompleteReason::ContentFilter
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}

///|
pub struct OpenResponsesIncompleteDetails {
  reason : OpenResponsesIncompleteReason?
}

///|
pub impl ToJson for OpenResponsesIncompleteDetails with to_json(
  self : OpenResponsesIncompleteDetails,
) -> Json {
  let object : Map[String, Json] = {}
  if self.reason is Some(reason) {
    object["reason"] = reason.to_json()
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for OpenResponsesIncompleteDetails with from_json(
  json : Json,
  path : @json.JsonPath,
) -> OpenResponsesIncompleteDetails raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.OpenResponsesIncompleteDetails::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let reason : OpenResponsesIncompleteReason? = match object.get("reason") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("reason")))
  }
  OpenResponsesIncompleteDetails::{ reason }
}
