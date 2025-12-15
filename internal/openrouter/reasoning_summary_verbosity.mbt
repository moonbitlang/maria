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
