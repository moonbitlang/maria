///|
pub(all) enum ResponseInputItem {
  Message(role~ : String, content~ : Array[ContentPart])
  FunctionCall(call_id~ : String, name~ : String, arguments~ : String)
  FunctionCallOutput(call_id~ : String, output~ : String)
} derive(Show)

///|
pub impl ToJson for ResponseInputItem with to_json(self : ResponseInputItem) -> Json {
  match self {
    Message(role~, content~) =>
      { "type": "message", "role": role, "content": content.to_json() }
    FunctionCall(call_id~, name~, arguments~) =>
      {
        "type": "function_call",
        "call_id": call_id,
        "name": name,
        "arguments": arguments,
      }
    FunctionCallOutput(call_id~, output~) =>
      { "type": "function_call_output", "call_id": call_id, "output": output }
  }
}

///|
pub(all) enum ResponseItem {
  Message(role~ : String, content~ : Array[ContentPart])
  FunctionCall(call_id~ : String, name~ : String, arguments~ : String)
} derive(Show)

///|
pub impl @json.FromJson for ResponseItem with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseItem raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ResponseItem: expected object"))
  }
  let type_ = match obj.get("type") {
    Some(String(s)) => s
    _ => raise @json.JsonDecodeError((path, "ResponseItem: missing 'type'"))
  }
  match type_ {
    "message" => {
      let role = match obj.get("role") {
        Some(String(s)) => s
        _ => raise @json.JsonDecodeError((path, "ResponseItem: missing 'role'"))
      }
      let content : Array[ContentPart] = match obj.get("content") {
        Some(content_json) =>
          @json.from_json(content_json, path=path.add_key("content"))
        None => []
      }
      Message(role~, content~)
    }
    "function_call" => {
      let call_id = match obj.get("call_id") {
        Some(String(s)) => s
        _ =>
          raise @json.JsonDecodeError((path, "ResponseItem: missing 'call_id'"))
      }
      let name = match obj.get("name") {
        Some(String(s)) => s
        _ => raise @json.JsonDecodeError((path, "ResponseItem: missing 'name'"))
      }
      let arguments = match obj.get("arguments") {
        Some(String(s)) => s
        _ =>
          raise @json.JsonDecodeError(
            (path, "ResponseItem: missing 'arguments'"),
          )
      }
      FunctionCall(call_id~, name~, arguments~)
    }
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseItem: unknown type '\{type_}'"),
      )
  }
}

///|
pub fn message_input(role~ : String, content~ : String) -> ResponseInputItem {
  Message(role~, content=[
    ContentPart::new(
      type_=if role == "user" { InputText } else { OutputText },
      text=content,
    ),
  ])
}

///|
pub fn function_call_output(
  call_id~ : String,
  output~ : String,
) -> ResponseInputItem {
  FunctionCallOutput(call_id~, output~)
}
