///|
enum UserMessageContent {
  Text(String)
  Items(Array[ChatMessageContentItem])
}

///|
pub impl ToJson for UserMessageContent with to_json(self : UserMessageContent) -> Json {
  match self {
    Text(text) => text.to_json()
    Items(items) => items.to_json()
  }
}
