///|
enum ChatGenerationParamsRoute {
  Fallback
  Sort
}

///|
pub impl ToJson for ChatGenerationParamsRoute with to_json(
  self : ChatGenerationParamsRoute,
) -> Json {
  match self {
    Fallback => "fallback"
    Sort => "sort"
  }
}

///|
pub impl @json.FromJson for ChatGenerationParamsRoute with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsRoute raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsRoute::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "fallback" => ChatGenerationParamsRoute::Fallback
    "sort" => ChatGenerationParamsRoute::Sort
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
