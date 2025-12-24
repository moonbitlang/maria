///|
pub struct ChatResponseChoice {
  finish_reason : ChatCompletionFinishReason?
  index : Int
  message : AssistantMessage
  logprobs : ChatMessageTokenLogprobs?
}

///|
pub impl ToJson for ChatResponseChoice with to_json(self : ChatResponseChoice) -> Json {
  let object : Map[String, Json] = { "index": self.index.to_json() }
  if self.finish_reason is Some(finish_reason) {
    object["finish_reason"] = finish_reason.to_json()
  }
  object["message"] = self.message.to_json()
  if self.logprobs is Some(logprobs) {
    object["logprobs"] = logprobs.to_json()
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for ChatResponseChoice with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatResponseChoice raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatResponseChoice::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let index : Int = match object.get("index") {
    Some(index_json) => @json.from_json(index_json, path=path.add_key("index"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("index"), "\{func_name}: missing field index"),
      )
  }
  let finish_reason : ChatCompletionFinishReason? = match
    object.get("finish_reason") {
    None | Some(Null) => None
    Some(finish_reason_json) =>
      Some(
        @json.from_json(finish_reason_json, path=path.add_key("finish_reason")),
      )
  }
  let message : AssistantMessage = match object.get("message") {
    Some(message_json) =>
      @json.from_json(message_json, path=path.add_key("message"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("message"), "\{func_name}: missing field message"),
      )
  }
  let logprobs : ChatMessageTokenLogprobs? = match object.get("logprobs") {
    None | Some(Null) => None
    Some(logprobs_json) =>
      Some(@json.from_json(logprobs_json, path=path.add_key("logprobs")))
  }
  ChatResponseChoice::{ finish_reason, index, message, logprobs }
}
