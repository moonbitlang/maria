///|
enum Message {
  System(SystemMessage)
  User(UserMessage)
  Developer(MessageDeveloper)
  Assistant(AssistantMessage)
  Tool(ToolResponseMessage)
}
