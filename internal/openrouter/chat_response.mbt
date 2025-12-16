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

///|
pub impl @json.FromJson for ChatResponse with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatResponse raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatResponse::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let id : String = match object.get("id") {
    Some(id_json) => @json.from_json(id_json, path=path.add_key("id"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("id"), "\{func_name}: missing field id"),
      )
  }
  let choices : Array[ChatResponseChoice] = match object.get("choices") {
    Some(choices_json) =>
      @json.from_json(choices_json, path=path.add_key("choices"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("choices"), "\{func_name}: missing field choices"),
      )
  }
  let created : Int = match object.get("created") {
    Some(created_json) =>
      @json.from_json(created_json, path=path.add_key("created"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("created"), "\{func_name}: missing field created"),
      )
  }
  let model : String = match object.get("model") {
    Some(model_json) => @json.from_json(model_json, path=path.add_key("model"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("model"), "\{func_name}: missing field model"),
      )
  }
  let object_field : String = match object.get("object") {
    Some(object_json) =>
      @json.from_json(object_json, path=path.add_key("object"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("object"), "\{func_name}: missing field object"),
      )
  }
  let system_fingerprint : String? = match object.get("system_fingerprint") {
    None | Some(Null) => None
    Some(system_fingerprint_json) =>
      Some(
        @json.from_json(
          system_fingerprint_json,
          path=path.add_key("system_fingerprint"),
        ),
      )
  }
  let usage : ChatGenerationTokenUsage? = match object.get("usage") {
    None | Some(Null) => None
    Some(usage_json) =>
      Some(@json.from_json(usage_json, path=path.add_key("usage")))
  }
  ChatResponse::{
    id,
    choices,
    created,
    model,
    object: object_field,
    system_fingerprint,
    usage,
  }
}
