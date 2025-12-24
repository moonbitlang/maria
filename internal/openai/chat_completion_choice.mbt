///|
/// Single choice returned in a chat completion response.
pub struct ChatCompletionChoice {
  finish_reason : ChatCompletionChoiceFinishReason?
  index : Int
  message : ChatCompletionMessage
} derive(Show)

///|
pub fn ChatCompletionChoice::new(
  finish_reason? : ChatCompletionChoiceFinishReason,
  index~ : Int,
  message~ : ChatCompletionMessage,
) -> ChatCompletionChoice {
  { finish_reason, index, message }
}

///|
impl ToJson for ChatCompletionChoice with to_json(self : ChatCompletionChoice) -> Json {
  let json : Map[String, Json] = {
    "index": self.index,
    "message": self.message,
  }
  if self.finish_reason is Some(finish_reason) {
    json["finish_reason"] = finish_reason.to_json()
  }
  Json::object(json)
}

///|
impl @json.FromJson for ChatCompletionChoice with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChoice {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let finish_reason = match json.get("finish_reason") {
    Some(Null) => None
    Some(finish_reason) => {
      let finish_reason : ChatCompletionChoiceFinishReason = @json.from_json(
        finish_reason,
        path=json_path.add_key("finish_reason"),
      )
      Some(finish_reason)
    }
    None => None
  }
  // index is optional (Copilot API may not return it), default to 0
  let index = match json.get("index") {
    Some(Number(index, ..)) => index.to_int()
    _ => 0
  }
  guard json.get("message") is Some(message) else {
    raise @json.JsonDecodeError((json_path, "Missing 'message' field"))
  }
  let message : ChatCompletionMessage = @json.from_json(
    message,
    path=json_path.add_key("message"),
  )
  ChatCompletionChoice::{ finish_reason, index, message }
}
