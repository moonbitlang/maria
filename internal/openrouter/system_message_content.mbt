///|
enum SystemMessageContent {
  Text(String)
  Items(Array[ChatMessageContentItemText])
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
