///|
/// Chat completion response metadata.
pub struct ChatCompletion {
  id : String
  choices : Array[ChatCompletionChoice]
  created : Int
  model : String
  usage : CompletionUsage?
  system_fingerprint : String?
  service_tier : ChatCompletionServiceTier?
} derive(Show)

///|
pub fn ChatCompletion::new(
  id~ : String,
  choices~ : Array[ChatCompletionChoice],
  created~ : Int,
  model~ : String,
  usage? : CompletionUsage,
  system_fingerprint? : String,
  service_tier? : ChatCompletionServiceTier,
) -> ChatCompletion {
  { id, choices, created, model, usage, system_fingerprint, service_tier }
}

///|
pub impl ToJson for ChatCompletion with to_json(self : ChatCompletion) -> Json {
  let json : Map[String, Json] = {
    "id": self.id,
    "choices": self.choices,
    "created": self.created,
    "model": Json::string(self.model),
  }
  if self.usage is Some(usage) {
    json["usage"] = usage.to_json()
  }
  if self.system_fingerprint is Some(fingerprint) {
    json["system_fingerprint"] = Json::string(fingerprint)
  }
  if self.service_tier is Some(service_tier) {
    json["service_tier"] = service_tier.to_json()
  }
  Json::object(json)
}

///|
pub impl @json.FromJson for ChatCompletion with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletion {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("id") is Some(String(id)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'id' field"))
  }
  guard json.get("choices") is Some(choices) else {
    raise @json.JsonDecodeError((json_path, "Missing 'choices' field"))
  }
  let choices : Array[ChatCompletionChoice] = @json.from_json(
    choices,
    path=json_path.add_key("choices"),
  )
  // created is optional for Copilot API compatibility
  let created = match json.get("created") {
    Some(Number(created, ..)) => created.to_int()
    _ => 0
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
      let service_tier : ChatCompletionServiceTier = @json.from_json(
        service_tier,
        path=json_path.add_key("service_tier"),
      )
      Some(service_tier)
    }
    None => None
  }
  ChatCompletion::{
    id,
    choices,
    created,
    model,
    usage,
    system_fingerprint,
    service_tier,
  }
}
