///|
enum OpenResponsesTruncation {
  Auto
  Disabled
}

///|
pub impl ToJson for OpenResponsesTruncation with to_json(
  self : OpenResponsesTruncation,
) -> Json {
  match self {
    Auto => "auto"
    Disabled => "disabled"
  }
}

///|
pub impl @json.FromJson for OpenResponsesTruncation with from_json(
  json : Json,
  path : @json.JsonPath,
) -> OpenResponsesTruncation raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.OpenResponsesTruncation::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "auto" => OpenResponsesTruncation::Auto
    "disabled" => OpenResponsesTruncation::Disabled
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
