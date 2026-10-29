///|
pub enum Message {
  User(String)
  System(String)
  Assistant(String, tool_calls~ : Array[ToolCall])
  Tool(String, tool_call_id~ : String)
} derive(ToJson, Eq, Debug)

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
  tool_calls~ : Array[ToolCall] = [],
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
} derive(ToJson, Eq, Debug)

///|
pub fn tool_call(id~ : String, name~ : String, arguments? : String) -> ToolCall {
  ToolCall::{ id, name, arguments, }
}

///|
pub struct Usage {
  input_tokens : Int32
  output_tokens : Int32
  total_tokens : Int32
  cache_read_tokens : Int32?
} derive(Eq, Debug)

///|
pub fn usage(
  input_tokens~ : Int32,
  output_tokens~ : Int32,
  total_tokens~ : Int32 = input_tokens + output_tokens,
  cache_read_tokens? : Int32,
) -> Usage {
  Usage::{ input_tokens, output_tokens, total_tokens, cache_read_tokens, }
}

///|
pub extend Message with ToJson::{to_json}

///|
pub extend Message with Eq::{not_equal, equal}

///|
pub extend Message with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ToolCall with ToJson::{to_json}

///|
pub extend ToolCall with Eq::{not_equal, equal}

///|
pub extend ToolCall with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Usage with Eq::{not_equal, equal}

///|
pub extend Usage with @moonbitlang/core/debug.Debug::{to_repr}
