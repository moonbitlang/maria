///|
enum ReasoningSummaryVerbosity {
  Disabled
  Low
  Medium
  High
}

///|
pub impl ToJson for ReasoningSummaryVerbosity with to_json(
  self : ReasoningSummaryVerbosity,
) -> Json {
  match self {
    Disabled => "disabled"
    Low => "low"
    Medium => "medium"
    High => "high"
  }
}

///|
pub impl @json.FromJson for ReasoningSummaryVerbosity with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ReasoningSummaryVerbosity raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ReasoningSummaryVerbosity::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "disabled" => ReasoningSummaryVerbosity::Disabled
    "low" => ReasoningSummaryVerbosity::Low
    "medium" => ReasoningSummaryVerbosity::Medium
    "high" => ReasoningSummaryVerbosity::High
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
