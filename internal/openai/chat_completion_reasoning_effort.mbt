///|
/// Reasoning effort control for reasoning models.
pub(all) enum ChatCompletionReasoningEffort {
  None_
  Minimal
  Low
  Medium
  High
  Xhigh
} derive(Show)

///|
impl ToJson for ChatCompletionReasoningEffort with to_json(
  self : ChatCompletionReasoningEffort,
) -> Json {
  match self {
    None_ => "none"
    Minimal => "minimal"
    Low => "low"
    Medium => "medium"
    High => "high"
    Xhigh => "xhigh"
  }
}
