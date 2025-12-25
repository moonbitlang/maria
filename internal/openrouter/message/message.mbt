///|
pub enum Message {
  System(SystemMessage)
  User(UserMessage)
  Developer(MessageDeveloper)
  Assistant(AssistantMessage)
  Tool(ToolResponseMessage)
}

///|
pub fn Message::new_user(content : String, name? : String) -> Message {
  Message::User(UserMessage::new(content, name?))
}

///|
pub fn Message::new_system(content : String, name? : String) -> Message {
  Message::System(SystemMessage::new(content, name?))
}

///|
pub fn Message::new_developer(
  content : MessageContent,
  name? : String,
) -> Message {
  Message::Developer(MessageDeveloper::{ content, name })
}

///|
pub fn Message::new_assistant(
  content : AssistantMessageContent,
  name? : String,
  tool_calls? : Array[ChatMessageToolCall],
  refusal? : String,
  reasoning? : String,
) -> Message {
  Message::Assistant(
    AssistantMessage::new(content, name?, tool_calls?, refusal?, reasoning?),
  )
}

///|
pub impl ToJson for Message with to_json(self : Message) -> Json {
  match self {
    System(msg) => msg.to_json()
    User(msg) => msg.to_json()
    Developer(msg) => msg.to_json()
    Assistant(msg) => msg.to_json()
    Tool(msg) => msg.to_json()
  }
}

///|
pub impl @json.FromJson for Message with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Message raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.Message::from_json"
  guard json is Object({ "role": String(role_str), .. }) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object with role"))
  }
  match role_str {
    "system" => Message::System(@json.from_json(json, path~))
    "user" => Message::User(@json.from_json(json, path~))
    "developer" => Message::Developer(@json.from_json(json, path~))
    "assistant" => Message::Assistant(@json.from_json(json, path~))
    "tool" => Message::Tool(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("role"), "\{func_name}: unknown role \"\{role_str}\""),
      )
  }
}
