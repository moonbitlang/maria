///|
pub struct AssistantMessage {
  content : AssistantMessageContent
  name : String?
  tool_calls : Array[@chat_message.ChatMessageToolCall]?
  refusal : String?
  reasoning : String?
}

///|
pub fn AssistantMessage::new(
  content : AssistantMessageContent,
  name? : String,
  tool_calls? : Array[@chat_message.ChatMessageToolCall],
  refusal? : String,
  reasoning? : String,
) -> AssistantMessage {
  AssistantMessage::{ content, name, tool_calls, refusal, reasoning }
}

///|
pub impl ToJson for AssistantMessage with to_json(self : AssistantMessage) -> Json {
  let object : Map[String, Json] = { "role": "assistant" }
  if self.name is Some(name) {
    object["name"] = name.to_json()
  }
  object["content"] = self.content.to_json()
  if self.tool_calls is Some(tool_calls) {
    object["tool_calls"] = tool_calls.to_json()
  }
  if self.refusal is Some(refusal) {
    object["refusal"] = refusal.to_json()
  }
  if self.reasoning is Some(reasoning) {
    object["reasoning"] = reasoning.to_json()
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for AssistantMessage with from_json(
  json : Json,
  path : @json.JsonPath,
) -> AssistantMessage raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.AssistantMessage::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let content : AssistantMessageContent = match object.get("content") {
    Some(content_json) =>
      @json.from_json(content_json, path=path.add_key("content"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("content"), "\{func_name}: missing field content"),
      )
  }
  let name : String? = match object.get("name") {
    None | Some(Null) => None
    Some(name_json) =>
      Some(@json.from_json(name_json, path=path.add_key("name")))
  }
  let tool_calls : Array[@chat_message.ChatMessageToolCall]? = match
    object.get("tool_calls") {
    None | Some(Null) => None
    Some(tool_calls_json) =>
      Some(@json.from_json(tool_calls_json, path=path.add_key("tool_calls")))
  }
  let refusal : String? = match object.get("refusal") {
    None | Some(Null) => None
    Some(refusal_json) =>
      Some(@json.from_json(refusal_json, path=path.add_key("refusal")))
  }
  let reasoning : String? = match object.get("reasoning") {
    None | Some(Null) => None
    Some(reasoning_json) =>
      Some(@json.from_json(reasoning_json, path=path.add_key("reasoning")))
  }
  AssistantMessage::{ content, name, tool_calls, refusal, reasoning }
}
