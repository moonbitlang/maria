///|
struct ToolResponseMessage {
  content : ToolResponseMessageContent
  tool_call_id : String
}

///|
pub impl ToJson for ToolResponseMessage with to_json(self : ToolResponseMessage) -> Json {
  let object : Map[String, Json] = {
    "role": "tool",
    "tool_call_id": self.tool_call_id.to_json(),
  }
  object["content"] = self.content.to_json()
  Json::object(object)
}
