///|
pub enum Message {
  User(String)
  System(String)
  Assistant(String, tool_calls~ : Array[ToolCall])
  Tool(String, tool_call_id~ : String)
} derive(ToJson)

///|
pub fn user_message(content~ : String) -> Message {
  Message::User(content)
}

///|
pub fn system_message(content~ : String) -> Message {
  Message::System(content)
}

///|
pub fn assistant_message(
  content~ : String,
  tool_calls? : Array[ToolCall] = [],
) -> Message {
  Message::Assistant(content, tool_calls~)
}

///|
pub fn tool_message(content~ : String, tool_call_id~ : String) -> Message {
  Message::Tool(content, tool_call_id~)
}

///|
pub fn Message::content(self : Message) -> String {
  match self {
    User(content) => content
    System(content) => content
    Assistant(content, ..) => content
    Tool(content, ..) => content
  }
}

///|
pub struct ToolCall {
  id : String
  name : String
  arguments : String?
} derive(ToJson)

///|
pub fn tool_call(id~ : String, name~ : String, arguments? : String) -> ToolCall {
  ToolCall::{ id, name, arguments }
}

///|
pub struct Usage {
  input_tokens : Int
  output_tokens : Int
  total_tokens : Int
  cache_read_tokens : Int?
}

///|
pub fn usage(
  input_tokens~ : Int,
  output_tokens~ : Int,
  total_tokens? : Int = input_tokens + output_tokens,
  cache_read_tokens? : Int,
) -> Usage {
  Usage::{ input_tokens, output_tokens, total_tokens, cache_read_tokens }
}
