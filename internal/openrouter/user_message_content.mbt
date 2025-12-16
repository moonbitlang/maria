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

///|
pub impl @json.FromJson for UserMessageContent with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> UserMessageContent {
  match json {
    String(text) => UserMessageContent::Text(text)
    Array(_) as items_json => {
      let items : Array[ChatMessageContentItem] = @json.from_json(
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
