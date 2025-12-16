///|
enum ToolResponseMessageContent {
  Text(String)
  Items(Array[ChatMessageContentItem])
}

///|
pub impl ToJson for ToolResponseMessageContent with to_json(
  self : ToolResponseMessageContent,
) -> Json {
  match self {
    Text(text) => text.to_json()
    Items(items) => items.to_json()
  }
}

///|
pub impl @json.FromJson for ToolResponseMessageContent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolResponseMessageContent raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ToolResponseMessageContent::from_json"
  match json {
    String(text) => ToolResponseMessageContent::Text(text)
    Array(_) as items_json =>
      ToolResponseMessageContent::Items(@json.from_json(items_json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: expect string or array"),
      )
  }
}
