///|
enum UserMessageContent {
  Text(String)
  Items(Array[@chat_message.ChatMessageContentItem])
}

///|
trait ToUserMessageContent {
  to_user_message_content(Self) -> UserMessageContent
}

///|
pub impl ToUserMessageContent for String with to_user_message_content(
  self : String,
) -> UserMessageContent {
  UserMessageContent::Text(self)
}

///|
pub impl ToUserMessageContent for Array[@chat_message.ChatMessageContentItem] with to_user_message_content(
  self : Array[@chat_message.ChatMessageContentItem],
) -> UserMessageContent {
  UserMessageContent::Items(self)
}

///|
pub impl ToJson for UserMessageContent with to_json(self : UserMessageContent) -> Json {
  match self {
    Text(text) => text.to_json()
    Items(items) => items.to_json()
  }
}

///|
pub impl @json.FromJson for UserMessageContent with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> UserMessageContent {
  match json {
    String(text) => UserMessageContent::Text(text)
    Array(_) as items_json => {
      let items : Array[@chat_message.ChatMessageContentItem] = @json.from_json(
        items_json,
        path=json_path,
      )
      UserMessageContent::Items(items)
    }
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "\{PackageName}.UserMessageContent: expect string or array"),
      )
  }
}
