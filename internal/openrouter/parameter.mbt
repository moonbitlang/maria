///|
pub(all) struct Parameter(String)

///|
pub impl ToJson for Parameter with to_json(self : Parameter) -> Json {
  self.0.to_json()
}

///|
pub impl @json.FromJson for Parameter with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Parameter raise @json.JsonDecodeError {
  Parameter(@json.from_json(json, path~))
}
