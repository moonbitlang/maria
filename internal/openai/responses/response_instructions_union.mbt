///|
/// Instructions for the response: a string or list of input items.
pub enum ResponseInstructions {
  Text(String)
  InputItemList(Array[ResponseInputItem])
}

///|
pub impl ToJson for ResponseInstructions with to_json(
  self : ResponseInstructions,
) -> Json {
  match self {
    Text(value) => value.to_json()
    InputItemList(items) => items.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseInstructions with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInstructions raise @json.JsonDecodeError {
  match json {
    String(value) => Text(value)
    Array(_) => InputItemList(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError((path, "ResponseInstructions: invalid value"))
  }
}
