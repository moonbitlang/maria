///|
enum AssistantMessageContent {
  Text(String)
  Items(Array[ChatMessageContentItem])
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
