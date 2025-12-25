///|
pub struct ChatCompletionChunk {
  id : String
  choices : Array[ChatCompletionChunkChoice]
  created : Int
  model : String
  usage : CompletionUsage?
  system_fingerprint : String?
  service_tier : ChatCompletionChunkServiceTier?
  error : OpenRouterErrorResponse?
} derive(ToJson)

///|
pub impl @json.FromJson for ChatCompletionChunk with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChunk {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("id") is Some(String(id)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'id' field"))
  }
  guard json.get("choices") is Some(choices) else {
    raise @json.JsonDecodeError((json_path, "Missing 'choices' field"))
  }
  let choices : Array[ChatCompletionChunkChoice] = @json.from_json(
    choices,
    path=json_path.add_key("choices"),
  )
  guard json.get("created") is Some(Number(created, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'created' field"))
  }
  guard json.get("model") is Some(String(model)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'model' field"))
  }
  let usage = match json.get("usage") {
    Some(Null) => None
    Some(usage) => {
      let usage : CompletionUsage = @json.from_json(
        usage,
        path=json_path.add_key("usage"),
      )
      Some(usage)
    }
    None => None
  }
  let system_fingerprint = match json.get("system_fingerprint") {
    Some(Null) => None
    Some(String(fingerprint)) => Some(fingerprint)
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'system_fingerprint' to be a string"),
      )
    None => None
  }
  let service_tier = match json.get("service_tier") {
    Some(Null) => None
    Some(service_tier) => {
      let service_tier : ChatCompletionChunkServiceTier = @json.from_json(
        service_tier,
        path=json_path.add_key("service_tier"),
      )
      Some(service_tier)
    }
    None => None
  }
  let error = match json.get("error") {
    Some(Null) => None
    Some(error) => {
      let error : OpenRouterErrorResponse = @json.from_json(
        error,
        path=json_path.add_key("error"),
      )
      Some(error)
    }
    None => None
  }
  ChatCompletionChunk::{
    id,
    choices,
    created: created.to_int(),
    model,
    usage,
    system_fingerprint,
    service_tier,
    error,
  }
}
