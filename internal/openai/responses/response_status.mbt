///|
/// Status of the response generation.
pub enum ResponseStatus {
  Completed
  Failed
  InProgress
  Cancelled
  Queued
  Incomplete
}

///|
pub impl ToJson for ResponseStatus with to_json(self : ResponseStatus) -> Json {
  match self {
    Completed => "completed"
    Failed => "failed"
    InProgress => "in_progress"
    Cancelled => "cancelled"
    Queued => "queued"
    Incomplete => "incomplete"
  }
}

///|
pub impl @json.FromJson for ResponseStatus with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseStatus raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError((path, "ResponseStatus: expected string"))
  }
  match value {
    "completed" => Completed
    "failed" => Failed
    "in_progress" => InProgress
    "cancelled" => Cancelled
    "queued" => Queued
    "incomplete" => Incomplete
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseStatus: invalid value '\{value}'"),
      )
  }
}
