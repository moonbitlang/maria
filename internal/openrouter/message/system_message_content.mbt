///|
enum SystemMessageContent {
  Text(String)
  Items(Array[@chat_message.ChatMessageContentItemText])
}

///|
pub impl ToJson for SystemMessageContent with to_json(
  self : SystemMessageContent,
) -> Json {
  match self {
    Text(text) => text.to_json()
    Items(items) => items.to_json()
  }
}

///|
pub impl @json.FromJson for SystemMessageContent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> SystemMessageContent raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.SystemMessageContent::from_json"
  match json {
    String(text) => SystemMessageContent::Text(text)
    Array(_) as items_json =>
      SystemMessageContent::Items(@json.from_json(items_json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: expect string or array"),
      )
  }
}
