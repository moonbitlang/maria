///|
/// Cache directives for individual content parts.
pub(all) enum CacheControl {
  Ephemeral
}

///|
pub impl ToJson for CacheControl with to_json(self : CacheControl) -> Json {
  match self {
    Ephemeral => { "type": "ephemeral" }
  }
}

///|
impl @json.FromJson for CacheControl with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> CacheControl {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("type") is Some(String(type_)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'type' field"))
  }
  match type_ {
    "ephemeral" => CacheControl::Ephemeral
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Unknown cache control type: \{type_}"),
      )
  }
}
