///|
struct ChatResponse {
  id : String
  choices : Array[ChatResponseChoice]
  created : Int
  model : String
  object : String
  system_fingerprint : String?
  usage : ChatGenerationTokenUsage?
}

///|
pub impl ToJson for ChatResponse with to_json(self : ChatResponse) -> Json {
  let object : Map[String, Json] = {
    "id": self.id.to_json(),
    "choices": self.choices.to_json(),
    "created": self.created.to_json(),
    "model": self.model.to_json(),
    "object": self.object.to_json(),
  }
  if self.system_fingerprint is Some(system_fingerprint) {
    object["system_fingerprint"] = system_fingerprint.to_json()
  }
  if self.usage is Some(usage) {
    object["usage"] = usage.to_json()
  }
  Json::object(object)
}
