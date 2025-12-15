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
