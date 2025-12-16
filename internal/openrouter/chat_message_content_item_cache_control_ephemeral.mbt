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

///|
pub impl @json.FromJson for ChatMessageContentItemCacheControlEphemeral with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatMessageContentItemCacheControlEphemeral raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatMessageContentItemCacheControlEphemeral::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((json_path, "\{func_name}: expect object"))
  }
  let ttl : Ttl? = match object.get("ttl") {
    None | Some(Null) => None
    Some(ttl_json) =>
      Some(@json.from_json(ttl_json, path=json_path.add_key("ttl")))
  }
  ChatMessageContentItemCacheControlEphemeral::{ ttl, }
}
