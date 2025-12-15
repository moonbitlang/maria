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
