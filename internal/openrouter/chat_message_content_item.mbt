///|
enum ChatMessageContentItem {
  Text(ChatMessageContentItemText)
}

///|
pub impl ToJson for ChatMessageContentItem with to_json(
  self : ChatMessageContentItem,
) -> Json {
  match self {
    Text(text) => text.to_json()
  }
}
