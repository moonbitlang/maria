///|
/// Reasoning effort for reasoning models.
pub enum ReasoningEffort {
  None_
  Minimal
  Low
  Medium
  High
  Xhigh
}

///|
pub impl ToJson for ReasoningEffort with to_json(self : ReasoningEffort) -> Json {
  match self {
    None_ => "none"
    Minimal => "minimal"
    Low => "low"
    Medium => "medium"
    High => "high"
    Xhigh => "xhigh"
  }
}

///|
pub impl @json.FromJson for ReasoningEffort with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ReasoningEffort raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError((path, "ReasoningEffort: expected string"))
  }
  match value {
    "none" => None_
    "minimal" => Minimal
    "low" => Low
    "medium" => Medium
    "high" => High
    "xhigh" => Xhigh
    _ =>
      raise @json.JsonDecodeError(
        (path, "ReasoningEffort: invalid value '\{value}'"),
      )
  }
}

///|
/// Deprecated reasoning summary mode.
pub enum ReasoningGenerateSummary {
  Auto
  Concise
  Detailed
}

///|
pub impl ToJson for ReasoningGenerateSummary with to_json(
  self : ReasoningGenerateSummary,
) -> Json {
  match self {
    Auto => "auto"
    Concise => "concise"
    Detailed => "detailed"
  }
}

///|
pub impl @json.FromJson for ReasoningGenerateSummary with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ReasoningGenerateSummary raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError(
      (path, "ReasoningGenerateSummary: expected string"),
    )
  }
  match value {
    "auto" => Auto
    "concise" => Concise
    "detailed" => Detailed
    _ =>
      raise @json.JsonDecodeError(
        (path, "ReasoningGenerateSummary: invalid value '\{value}'"),
      )
  }
}

///|
/// Reasoning summary mode.
pub enum ReasoningSummary {
  Auto
  Concise
  Detailed
}

///|
pub impl ToJson for ReasoningSummary with to_json(self : ReasoningSummary) -> Json {
  match self {
    Auto => "auto"
    Concise => "concise"
    Detailed => "detailed"
  }
}

///|
pub impl @json.FromJson for ReasoningSummary with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ReasoningSummary raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError((path, "ReasoningSummary: expected string"))
  }
  match value {
    "auto" => Auto
    "concise" => Concise
    "detailed" => Detailed
    _ =>
      raise @json.JsonDecodeError(
        (path, "ReasoningSummary: invalid value '\{value}'"),
      )
  }
}

///|
/// Reasoning configuration for responses.
pub struct Reasoning {
  effort : ReasoningEffort?
  generate_summary : ReasoningGenerateSummary?
  summary : ReasoningSummary?
}

///|
pub impl ToJson for Reasoning with to_json(self : Reasoning) -> Json {
  let obj : Map[String, Json] = {}
  if self.effort is Some(effort) {
    obj["effort"] = effort.to_json()
  }
  if self.generate_summary is Some(generate_summary) {
    obj["generate_summary"] = generate_summary.to_json()
  }
  if self.summary is Some(summary) {
    obj["summary"] = summary.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for Reasoning with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Reasoning raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let effort : ReasoningEffort? = object.optional("effort", path~)
  let generate_summary : ReasoningGenerateSummary? = object.optional(
    "generate_summary",
    path~,
  )
  let summary : ReasoningSummary? = object.optional("summary", path~)
  Reasoning::{ effort, generate_summary, summary }
}
