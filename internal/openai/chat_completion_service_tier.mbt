///|
/// Service tier override for chat completion requests.
#alias(ChatCompletionChunkServiceTier)
pub(all) enum ChatCompletionServiceTier {
  Auto
  Default
  Flex
  Scale
  Priority
} derive(Show)

///|
impl @json.FromJson for ChatCompletionServiceTier with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionServiceTier {
  guard json is String(tier) else {
    raise @json.JsonDecodeError((json_path, "Expected a string"))
  }
  match tier {
    "auto" => ChatCompletionServiceTier::Auto
    "default" => ChatCompletionServiceTier::Default
    "flex" => ChatCompletionServiceTier::Flex
    "scale" => ChatCompletionServiceTier::Scale
    "priority" => ChatCompletionServiceTier::Priority
    _ =>
      raise @json.JsonDecodeError((json_path, "Unknown service tier: \{tier}"))
  }
}

///|
impl ToJson for ChatCompletionServiceTier with to_json(
  self : ChatCompletionServiceTier,
) -> Json {
  match self {
    Auto => "auto"
    Default => "default"
    Flex => "flex"
    Scale => "scale"
    Priority => "priority"
  }
}
