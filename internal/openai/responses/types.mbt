///|
/// Types and JSON helpers for the OpenAI Responses API.
///
/// This is extracted from `oauth/codex` so that `internal/openai` owns the
/// request/stream item wire types.

///|
pub struct ResponsesRequest {
  model : String
  input : Array[ResponseInputItemParam]
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
pub fn ContentPart::text(self : ContentPart) -> String {
  self.text
}

///|
pub fn ContentPart::type_(self : ContentPart) -> ContentType {
  self.type_
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
  let object = @jsonx.as_object(json, path~)
  let type_ : ContentType = object.required("type", path~)
  let text : String = object.required("text", path~)
  { type_, text }
}

///|
pub fn ResponsesRequest::new(
  model~ : String,
  input~ : Array[ResponseInputItemParam],
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
pub fn function_call_output(
  call_id~ : String,
  output~ : String,
) -> ResponseInputItemParam {
  FunctionCallOutput(call_id~, output~)
}

///|
pub fn function_call(
  call_id~ : String,
  name~ : String,
  arguments~ : String,
) -> ResponseInputItemParam {
  FunctionCall(call_id~, name~, arguments~)
}

///|
pub fn message_input(
  role~ : String,
  content~ : String,
) -> ResponseInputItemParam {
  let role_enum = match role {
    "user" => EasyInputMessageRole::User
    "assistant" => EasyInputMessageRole::Assistant
    "system" => EasyInputMessageRole::System
    "developer" => EasyInputMessageRole::Developer
    _ => EasyInputMessageRole::User
  }
  ResponseInputItemParam::message(role=role_enum, content~)
}
