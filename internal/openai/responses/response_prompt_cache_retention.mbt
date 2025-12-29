///|
/// The retention policy for the prompt cache.
pub enum ResponsePromptCacheRetention {
  InMemory
  H24
}

///|
pub impl ToJson for ResponsePromptCacheRetention with to_json(
  self : ResponsePromptCacheRetention,
) -> Json {
  match self {
    InMemory => "in-memory"
    H24 => "24h"
  }
}

///|
pub impl @json.FromJson for ResponsePromptCacheRetention with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponsePromptCacheRetention raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError(
      (path, "ResponsePromptCacheRetention: expected string"),
    )
  }
  match value {
    "in-memory" => InMemory
    "24h" => H24
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponsePromptCacheRetention: invalid value '\{value}'"),
      )
  }
}
