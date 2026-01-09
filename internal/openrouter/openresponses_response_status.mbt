///|
enum OpenResponsesResponseStatus {
  Completed
  Incomplete
  InProgress
  Failed
  Cancelled
  Queued
}

///|
pub impl ToJson for OpenResponsesResponseStatus with to_json(
  self : OpenResponsesResponseStatus,
) -> Json {
  match self {
    Completed => "completed"
    Incomplete => "incomplete"
    InProgress => "in_progress"
    Failed => "failed"
    Cancelled => "cancelled"
    Queued => "queued"
  }
}

///|
pub impl @json.FromJson for OpenResponsesResponseStatus with from_json(
  json : Json,
  path : @json.JsonPath,
) -> OpenResponsesResponseStatus raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.OpenResponsesResponseStatus::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "completed" => OpenResponsesResponseStatus::Completed
    "incomplete" => OpenResponsesResponseStatus::Incomplete
    "in_progress" => OpenResponsesResponseStatus::InProgress
    "failed" => OpenResponsesResponseStatus::Failed
    "cancelled" => OpenResponsesResponseStatus::Cancelled
    "queued" => OpenResponsesResponseStatus::Queued
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
