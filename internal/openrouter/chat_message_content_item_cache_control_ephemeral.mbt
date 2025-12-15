///|
struct ChatMessageContentItemCacheControlEphemeral {
  ttl : Ttl?
}

///|
pub impl ToJson for ChatMessageContentItemCacheControlEphemeral with to_json(
  self : ChatMessageContentItemCacheControlEphemeral,
) -> Json {
  let object : Map[String, Json] = { "type": "ephemeral" }
  if self.ttl is Some(ttl) {
    object["ttl"] = ttl.to_json()
  }
  object.to_json()
}
