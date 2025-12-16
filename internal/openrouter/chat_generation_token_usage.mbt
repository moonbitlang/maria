///|
struct ChatGenerationTokenUsage {
  completion_tokens : Int
  prompt_tokens : Int
  total_tokens : Int
  completion_tokens_details : CompletionTokensDetails?
  prompt_tokens_details : PromptTokensDetails?
}

///|
pub impl ToJson for ChatGenerationTokenUsage with to_json(
  self : ChatGenerationTokenUsage,
) -> Json {
  let object : Map[String, Json] = {
    "completion_tokens": self.completion_tokens.to_json(),
    "prompt_tokens": self.prompt_tokens.to_json(),
    "total_tokens": self.total_tokens.to_json(),
  }
  if self.completion_tokens_details is Some(completion_tokens_details) {
    object["completion_tokens_details"] = completion_tokens_details.to_json()
  }
  if self.prompt_tokens_details is Some(prompt_tokens_details) {
    object["prompt_tokens_details"] = prompt_tokens_details.to_json()
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for ChatGenerationTokenUsage with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationTokenUsage raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationTokenUsage::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let completion_tokens : Int = match object.get("completion_tokens") {
    Some(v) => @json.from_json(v, path=path.add_key("completion_tokens"))
    None =>
      raise @json.JsonDecodeError(
        (
          path.add_key("completion_tokens"),
          "\{func_name}: missing field completion_tokens",
        ),
      )
  }
  let prompt_tokens : Int = match object.get("prompt_tokens") {
    Some(v) => @json.from_json(v, path=path.add_key("prompt_tokens"))
    None =>
      raise @json.JsonDecodeError(
        (
          path.add_key("prompt_tokens"),
          "\{func_name}: missing field prompt_tokens",
        ),
      )
  }
  let total_tokens : Int = match object.get("total_tokens") {
    Some(v) => @json.from_json(v, path=path.add_key("total_tokens"))
    None =>
      raise @json.JsonDecodeError(
        (
          path.add_key("total_tokens"),
          "\{func_name}: missing field total_tokens",
        ),
      )
  }
  let completion_tokens_details : CompletionTokensDetails? = match
    object.get("completion_tokens_details") {
    None | Some(Null) => None
    Some(v) =>
      Some(@json.from_json(v, path=path.add_key("completion_tokens_details")))
  }
  let prompt_tokens_details : PromptTokensDetails? = match
    object.get("prompt_tokens_details") {
    None | Some(Null) => None
    Some(v) =>
      Some(@json.from_json(v, path=path.add_key("prompt_tokens_details")))
  }
  ChatGenerationTokenUsage::{
    completion_tokens,
    prompt_tokens,
    total_tokens,
    completion_tokens_details,
    prompt_tokens_details,
  }
}
