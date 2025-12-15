///|
enum Message {
  System(SystemMessage)
  User(UserMessage)
  Developer(MessageDeveloper)
  Assistant(AssistantMessage)
  Tool(ToolResponseMessage)
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
