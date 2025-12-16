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

///|
pub impl @json.FromJson for ToolResponseMessage with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolResponseMessage raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ToolResponseMessage::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let content : ToolResponseMessageContent = match object.get("content") {
    Some(content_json) =>
      @json.from_json(content_json, path=path.add_key("content"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("content"), "\{func_name}: missing field content"),
      )
  }
  let tool_call_id : String = match object.get("tool_call_id") {
    Some(tool_call_id_json) =>
      @json.from_json(tool_call_id_json, path=path.add_key("tool_call_id"))
    None =>
      raise @json.JsonDecodeError(
        (
          path.add_key("tool_call_id"),
          "\{func_name}: missing field tool_call_id",
        ),
      )
  }
  ToolResponseMessage::{ content, tool_call_id }
}
