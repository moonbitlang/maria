///|
pub(all) enum ResponseItem {
  Message(role~ : String, content~ : Array[ContentPart])
  FunctionCall(call_id~ : String, name~ : String, arguments~ : String)
} derive(Show)

///|
pub impl ToJson for ResponseItem with to_json(self : ResponseItem) -> Json {
  match self {
    Message(role~, content~) =>
      { "type": "message", "role": role, "content": content }
    FunctionCall(call_id~, name~, arguments~) =>
      {
        "type": "function_call",
        "call_id": call_id,
        "name": name,
        "arguments": arguments,
      }
  }
}

///|
pub impl @json.FromJson for ResponseItem with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseItem raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : String = object.required("type", path~)
  match type_ {
    "message" => {
      let role : String = object.required("role", path~)
      let content : Array[ContentPart] = match
        object.optional("content", path~) {
        None => []
        Some(content) => content
      }
      Message(role~, content~)
    }
    "function_call" => {
      let call_id : String = object.required("call_id", path~)
      let name : String = object.required("name", path~)
      let arguments : String = object.required("arguments", path~)
      FunctionCall(call_id~, name~, arguments~)
    }
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseItem: unknown type '\{type_}'"),
      )
  }
}
