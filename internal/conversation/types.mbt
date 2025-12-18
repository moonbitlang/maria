///|
struct Conversation {
  clock : &@clock.Clock
  name : String
  description : String?
  id : @uuid.Uuid
  mut system_prompt : String?
  messages : Array[Message]
  created_at : @clock.Timestamp
  mut updated_at : @clock.Timestamp
  cwd : StringView
}

///|
pub fn Conversation::cwd(self : Conversation) -> StringView {
  self.cwd
}

///|
priv struct Message {
  /// The Unix timestamp (in seconds) of when the message was created.
  timestamp : @clock.Timestamp
  /// Usage statistics for the completion request.
  usage : @ai.Usage?
  message : @ai.Message
}
