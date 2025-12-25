///|
enum Effort {
  None
  Minimal
  Low
  Medium
  High
}

///|
pub impl ToJson for Effort with to_json(self : Effort) -> Json {
  match self {
    None => "none"
    Minimal => "minimal"
    Low => "low"
    Medium => "medium"
    High => "high"
  }
}

///|
pub impl @json.FromJson for Effort with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Effort raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.Effort::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "none" => Effort::None
    "minimal" => Effort::Minimal
    "low" => Effort::Low
    "medium" => Effort::Medium
    "high" => Effort::High
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
