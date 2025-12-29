///|
/// Types and JSON helpers for the OpenAI Responses API.
///
/// This is extracted from `oauth/codex` so that `internal/openai` owns the
/// request/stream item wire types.

///|
pub struct ResponsesRequest {
  model : String
  input : Array[ResponseInputItem]
  instructions : String
  tools : Array[Json]
  tool_choice : String
  stream : Bool?
  store : Bool?
} derive(Show)

///|
/// This is the minimal subset of Responses API content we currently need.
pub(all) enum ContentType {
  InputText
  OutputText
  Text
} derive(Show)

///|
pub impl ToJson for ContentType with to_json(self : ContentType) -> Json {
  match self {
    InputText => "input_text"
    OutputText => "output_text"
    Text => "text"
  }
}

///|
pub impl @json.FromJson for ContentType with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ContentType raise @json.JsonDecodeError {
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "ContentType: expected string"))
  }
  match s {
    "input_text" => InputText
    "output_text" => OutputText
    "text" => Text
    _ =>
      raise @json.JsonDecodeError((path, "ContentType: invalid value '\{s}'"))
  }
}

///|
pub struct ContentPart {
  type_ : ContentType
  text : String
} derive(Show)

///|
pub fn ContentPart::new(type_~ : ContentType, text~ : String) -> ContentPart {
  { type_, text }
}

///|
pub impl ToJson for ContentPart with to_json(self : ContentPart) -> Json {
  { "type": self.type_, "text": self.text }
}

///|
pub impl @json.FromJson for ContentPart with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ContentPart raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ContentPart: expected object"))
  }
  let type_ : ContentType = match obj.get("type") {
    Some(v) => @json.from_json(v, path=path.add_key("type"))
    None => raise @json.JsonDecodeError((path, "ContentPart: missing 'type'"))
  }
  let text : String = match obj.get("text") {
    Some(String(s)) => s
    Some(_) =>
      raise @json.JsonDecodeError((path, "ContentPart: 'text' must be string"))
    None => raise @json.JsonDecodeError((path, "ContentPart: missing 'text'"))
  }
  { type_, text }
}

///|
pub fn ResponsesRequest::new(
  model~ : String,
  input~ : Array[ResponseInputItem],
  instructions~ : String,
  tools? : Array[Json] = [],
  tool_choice? : String = "auto",
  stream? : Bool,
  store? : Bool,
) -> ResponsesRequest {
  { model, input, instructions, tools, tool_choice, stream, store }
}

///|
pub impl ToJson for ResponsesRequest with to_json(self : ResponsesRequest) -> Json {
  let obj = {
    "model": self.model.to_json(),
    "input": self.input.to_json(),
    "instructions": self.instructions.to_json(),
    "tools": self.tools.to_json(),
    "tool_choice": self.tool_choice.to_json(),
  }
  if self.stream is Some(v) {
    obj["stream"] = v.to_json()
  }
  if self.store is Some(v) {
    obj["store"] = v.to_json()
  }
  Json::object(obj)
}

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
