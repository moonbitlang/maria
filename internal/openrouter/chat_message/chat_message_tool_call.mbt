///|
enum ChatMessageToolCall {
  Function(ChatMessageToolCallFunction)
}

///|
pub impl ToJson for ChatMessageToolCall with to_json(self : ChatMessageToolCall) -> Json {
  match self {
    Function(func) => func.to_json()
  }
}

///|
pub impl @json.FromJson for ChatMessageToolCall with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatMessageToolCall raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatMessageToolCall::from_json"
  guard json is Object({ "type": String(type_str), .. }) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object with type"))
  }
  match type_str {
    "function" => ChatMessageToolCall::Function(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("type"), "\{func_name}: unknown type \"\{type_str}\""),
      )
  }
}
