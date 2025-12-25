///|
enum ChatGenerationParamsDataCollection {
  Deny
  Allow
}

///|
pub impl ToJson for ChatGenerationParamsDataCollection with to_json(
  self : ChatGenerationParamsDataCollection,
) -> Json {
  match self {
    Deny => "deny"
    Allow => "allow"
  }
}

///|
pub impl @json.FromJson for ChatGenerationParamsDataCollection with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsDataCollection raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsDataCollection::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "deny" => ChatGenerationParamsDataCollection::Deny
    "allow" => ChatGenerationParamsDataCollection::Allow
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
