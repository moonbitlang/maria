///|
enum ChatMessageContentItemCacheControl {
  Ephemeral(ChatMessageContentItemCacheControlEphemeral)
}

///|
pub impl ToJson for ChatMessageContentItemCacheControl with to_json(
  self : ChatMessageContentItemCacheControl,
) -> Json {
  match self {
    Ephemeral(ephemeral) => ephemeral.to_json()
  }
}
