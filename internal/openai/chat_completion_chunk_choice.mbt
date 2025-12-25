///|
/// Streaming choice wrapper returned by the API.
pub struct ChatCompletionChunkChoice {
  index : Int
  delta : ChatCompletionChunkChoiceDelta
  finish_reason : ChatCompletionChoiceFinishReason?
} derive(ToJson)

///|
impl @json.FromJson for ChatCompletionChunkChoice with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChunkChoice {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("index") is Some(Number(index, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'index' field"))
  }
  guard json.get("delta") is Some(delta) else {
    raise @json.JsonDecodeError((json_path, "Missing 'delta' field"))
  }
  let delta : ChatCompletionChunkChoiceDelta = @json.from_json(
    delta,
    path=json_path.add_key("delta"),
  )
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
  ChatCompletionChunkChoice::{ index: index.to_int(), delta, finish_reason }
}
