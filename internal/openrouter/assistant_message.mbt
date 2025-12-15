///|
struct AssistantMessage {
  content : AssistantMessageContent
  name : String?
  tool_calls : Array[ChatMessageToolCall]?
  refusal : String?
  reasoning : String?
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
