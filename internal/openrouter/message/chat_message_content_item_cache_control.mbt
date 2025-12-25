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

///|
pub impl @json.FromJson for ChatMessageContentItemCacheControl with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatMessageContentItemCacheControl raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatMessageContentItemCacheControl::from_json"
  guard json is Object({ "type": String(type_str), .. }) else {
    raise @json.JsonDecodeError(
      (json_path, "\{func_name}: expect object with 'type' field of string"),
    )
  }
  match type_str {
    "ephemeral" => {
      let cache_control_ephemeral : ChatMessageContentItemCacheControlEphemeral = @json.from_json(
        json,
        path=json_path,
      )
      ChatMessageContentItemCacheControl::Ephemeral(cache_control_ephemeral)
    }
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("type"), "\{func_name}: unknown type '\{type_str}'"),
      )
  }
}
