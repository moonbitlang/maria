///|
enum OpenResponsesServiceTier {
  Auto
  Default
  Flex
  Priority
  Scale
}

///|
pub impl ToJson for OpenResponsesServiceTier with to_json(
  self : OpenResponsesServiceTier,
) -> Json {
  match self {
    Auto => "auto"
    Default => "default"
    Flex => "flex"
    Priority => "priority"
    Scale => "scale"
  }
}

///|
pub impl @json.FromJson for OpenResponsesServiceTier with from_json(
  json : Json,
  path : @json.JsonPath,
) -> OpenResponsesServiceTier raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.OpenResponsesServiceTier::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "auto" => OpenResponsesServiceTier::Auto
    "default" => OpenResponsesServiceTier::Default
    "flex" => OpenResponsesServiceTier::Flex
    "priority" => OpenResponsesServiceTier::Priority
    "scale" => OpenResponsesServiceTier::Scale
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
