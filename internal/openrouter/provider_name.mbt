///|
pub(all) struct ProviderName(String)

///|
pub impl ToJson for ProviderName with to_json(self : ProviderName) -> Json {
  self.0.to_json()
}

///|
pub impl @json.FromJson for ProviderName with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ProviderName raise @json.JsonDecodeError {
  ProviderName(@json.from_json(json, path~))
}
