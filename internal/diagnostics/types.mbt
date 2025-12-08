///|
// TODO: rename_all() does not work
pub(all) enum Level {
  Error
  Warning
} derive(Show, ToJson, Eq)

///|
pub impl @json.FromJson for Level with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Level raise @json.JsonDecodeError {
  match json {
    "error" | "Error" => Level::Error
    "warning" | "Warning" => Level::Warning
    _ =>
      raise @json.JsonDecodeError((json_path, "Expected 'error' or 'warning'."))
  }
}

///|
pub(all) struct Pos {
  col : Int
  line : Int
} derive(Show, ToJson, FromJson, Eq)

///|
pub(all) struct Loc {
  end : Pos
  path : String
  start : Pos
} derive(Show, ToJson, FromJson, Eq)

///|
// FromJson is used when parsing `moon check --output json`
pub(all) struct Diagnostic {
  error_code : Int
  level : Level
  loc : Loc
  message : String
} derive(Show, ToJson, FromJson, Eq)
