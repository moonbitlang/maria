///|
enum MessageContent {
  Text(String)
  Items(Array[ChatMessageContentItemText])
}

///|
pub impl ToJson for MessageContent with to_json(self : MessageContent) -> Json {
  match self {
    Text(text) => text.to_json()
    Items(items) => items.to_json()
  }
}

///|
pub impl @json.FromJson for MessageContent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> MessageContent raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.MessageContent::from_json"
  match json {
    String(text) => MessageContent::Text(text)
    Array(_) as items_json =>
      MessageContent::Items(@json.from_json(items_json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: expect string or array"),
      )
  }
}
