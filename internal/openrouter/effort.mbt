///|
enum Effort {
  None
  Minimal
  Low
  Medium
  High
  Xhigh
}

///|
pub impl ToJson for Effort with to_json(self : Effort) -> Json {
  match self {
    None => "none"
    Minimal => "minimal"
    Low => "low"
    Medium => "medium"
    High => "high"
    Xhigh => "xhigh"
  }
}
