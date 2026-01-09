///|
enum OpenResponsesInput {
  Text(String)
  Items(Array[Json])
}

///|
pub impl ToJson for OpenResponsesInput with to_json(
  self : OpenResponsesInput,
) -> Json {
  match self {
    Text(text) => text.to_json()
    Items(items) => items.to_json()
  }
}

///|
pub impl @json.FromJson for OpenResponsesInput with from_json(
  json : Json,
  path : @json.JsonPath,
) -> OpenResponsesInput raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.OpenResponsesInput::from_json"
  match json {
    String(text) => OpenResponsesInput::Text(text)
    Array(items) => OpenResponsesInput::Items(items)
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: expect string or array"),
      )
  }
}
