///|
/// The status of the message input. One of `in_progress`, `completed`, or
/// `incomplete`. Populated when input items are returned via API.
pub(all) enum ResponseOutputMessageStatus {
  InProgress
  Completed
  Incomplete
} derive(Show)

///|
pub impl ToJson for ResponseOutputMessageStatus with to_json(
  self : ResponseOutputMessageStatus,
) -> Json {
  match self {
    InProgress => "in_progress"
    Completed => "completed"
    Incomplete => "incomplete"
  }
}

///|
pub impl @json.FromJson for ResponseOutputMessageStatus with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputMessageStatus raise @json.JsonDecodeError {
  guard json is String(status_str) else {
    raise @json.JsonDecodeError(
      (path, "ResponseOutputMessageStatus: expected string"),
    )
  }
  match status_str {
    "in_progress" => InProgress
    "completed" => Completed
    "incomplete" => Incomplete
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseOutputMessageStatus: invalid status '\{status_str}'"),
      )
  }
}
