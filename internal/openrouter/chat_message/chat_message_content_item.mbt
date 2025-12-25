///|
pub enum ChatMessageContentItem {
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

///|
pub impl @json.FromJson for ChatMessageContentItem with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatMessageContentItem {
  guard json is Object({ "type": String(type_str), .. }) else {
    raise @json.JsonDecodeError(
      (
        json_path,
        "\{PackageName}.ChatMessageContentItem: expect object with 'type' field of string",
      ),
    )
  }
  match type_str {
    "text" => {
      let item_text : ChatMessageContentItemText = @json.from_json(
        json,
        path=json_path,
      )
      ChatMessageContentItem::Text(item_text)
    }
    _ =>
      raise @json.JsonDecodeError(
        (
          json_path.add_key("type"),
          "\{PackageName}.ChatMessageContentItem: unknown type '\{type_str}'",
        ),
      )
  }
}
