///|
pub(all) enum ResponseInputItemMessageParamStatus {
  InProgress
  Completed
  Incomplete
} derive(Show)

///|
pub impl ToJson for ResponseInputItemMessageParamStatus with to_json(
  self : ResponseInputItemMessageParamStatus,
) -> Json {
  match self {
    InProgress => "in_progress"
    Completed => "completed"
    Incomplete => "incomplete"
  }
}

///|
pub impl @json.FromJson for ResponseInputItemMessageParamStatus with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemMessageParamStatus raise @json.JsonDecodeError {
  guard json is String(status_str) else {
    raise @json.JsonDecodeError(
      (path, "ResponseInputItemMessageParamStatus: expected string"),
    )
  }
  match status_str {
    "in_progress" => InProgress
    "completed" => Completed
    "incomplete" => Incomplete
    _ =>
      raise @json.JsonDecodeError(
        (
          path,
          "ResponseInputItemMessageParamStatus: invalid status '\{status_str}'",
        ),
      )
  }
}
