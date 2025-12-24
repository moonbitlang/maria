///|
/// Assistant message returned by chat completions.
pub struct ChatCompletionMessage {
  content : String?
  refusal : String?
  role : ChatCompletionMessageRole
  tool_calls : Array[ChatCompletionMessageToolCall]
} derive(Show, ToJson)

///|
pub fn ChatCompletionMessage::new(
  content? : String,
  refusal? : String,
  role? : ChatCompletionMessageRole = Assistant,
  tool_calls? : Array[ChatCompletionMessageToolCall] = [],
) -> ChatCompletionMessage {
  { content, refusal, role, tool_calls }
}

///|
pub fn ChatCompletionMessage::to_param(
  self : ChatCompletionMessage,
) -> ChatCompletionMessageParam {
  let parts = []
  if self.content is Some(content) {
    parts.push(text_content_part(content))
  }
  Assistant({ content: parts, name: None, tool_calls: self.tool_calls })
}

///|
pub impl @json.FromJson for ChatCompletionMessage with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionMessage {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let content = match json.get("content") {
    Some(Null) => None
    Some(content) => {
      let content : String = @json.from_json(
        content,
        path=json_path.add_key("content"),
      )
      Some(content)
    }
    None => None
  }
  let refusal = match json.get("refusal") {
    Some(Null) => None
    Some(refusal) => {
      let refusal : String = @json.from_json(
        refusal,
        path=json_path.add_key("refusal"),
      )
      Some(refusal)
    }
    None => None
  }
  let tool_calls = match json.get("tool_calls") {
    Some(tool_calls) => {
      let tool_calls : Array[ChatCompletionMessageToolCall] = @json.from_json(
        tool_calls,
        path=json_path.add_key("tool_calls"),
      )
      tool_calls
    }
    None => []
  }
  ChatCompletionMessage::{ content, refusal, role: Assistant, tool_calls }
}
