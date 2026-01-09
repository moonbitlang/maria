///|
/// Processing tier used for serving the request.
pub enum ResponseServiceTier {
  Auto
  Default
  Flex
  Scale
  Priority
}

///|
pub impl ToJson for ResponseServiceTier with to_json(self : ResponseServiceTier) -> Json {
  match self {
    Auto => "auto"
    Default => "default"
    Flex => "flex"
    Scale => "scale"
    Priority => "priority"
  }
}

///|
pub impl @json.FromJson for ResponseServiceTier with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseServiceTier raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError((path, "ResponseServiceTier: expected string"))
  }
  match value {
    "auto" => Auto
    "default" => Default
    "flex" => Flex
    "scale" => Scale
    "priority" => Priority
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseServiceTier: invalid value '\{value}'"),
      )
  }
}
