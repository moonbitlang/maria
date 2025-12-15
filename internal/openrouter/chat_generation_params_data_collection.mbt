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
