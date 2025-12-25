///|
enum AssistantMessageContent {
  Text(String)
  Items(Array[@chat_message.ChatMessageContentItem])
}

///|
pub fn AssistantMessageContent::text(self : AssistantMessageContent) -> String {
  match self {
    Text(text) => text
    Items(items) => {
      let texts = []
      for item in items {
        match item {
          @chat_message.ChatMessageContentItem::Text(text_item) =>
            texts.push(text_item.text)
        }
      }
      texts.join("")
    }
  }
}

///|
pub impl ToJson for AssistantMessageContent with to_json(
  self : AssistantMessageContent,
) -> Json {
  match self {
    Text(text) => text.to_json()
    Items(items) => items.to_json()
  }
}

///|
pub impl @json.FromJson for AssistantMessageContent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> AssistantMessageContent raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.AssistantMessageContent::from_json"
  match json {
    String(text) => AssistantMessageContent::Text(text)
    Array(_) as items_json =>
      AssistantMessageContent::Items(@json.from_json(items_json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: expect string or array"),
      )
  }
}
