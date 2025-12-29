///|
pub enum ResponseInputItemParam {
  Message(EasyInputMessageParam)
  InputMessage(ResponseInputItemMessageParam)
  FunctionCall(call_id~ : String, name~ : String, arguments~ : String)
  FunctionCallOutput(call_id~ : String, output~ : String)
} derive(Show)

///|
pub impl ToJson for ResponseInputItemParam with to_json(
  self : ResponseInputItemParam,
) -> Json {
  match self {
    Message(message) => message.to_json()
    InputMessage(input_message) => input_message.to_json()
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
pub fn[T : ToEasyInputMessageContentParam] ResponseInputItemParam::message(
  role~ : EasyInputMessageRole,
  content~ : T,
) -> ResponseInputItemParam {
  Message(EasyInputMessageParam::{
    role,
    content: content.to_easy_input_message_content_param(),
  })
}

///|
pub fn ResponseInputItemMessageParam::input_message(
  role : ResponseInputItemMessageParamRole,
  content : ResponseInputMessageContentListParam,
) -> ResponseInputItemParam {
  InputMessage(ResponseInputItemMessageParam::{ content, role, status: None })
}
