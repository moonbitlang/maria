///|
struct Conversation {
  clock : &@clock.Clock
  name : String
  description : String?
  id : @uuid.Uuid
  events : Array[@event.Event]
  created_at : @clock.Timestamp
  mut updated_at : @clock.Timestamp
  cwd : String
}

///|
pub fn Conversation::cwd(self : Conversation) -> String {
  self.cwd
}

///|
pub fn Conversation::events(self : Conversation) -> ArrayView[@event.Event] {
  self.events
}

///|
priv struct Message {
  /// The Unix timestamp (in milliseconds) of when the message was created.
  timestamp : @clock.Timestamp
  /// Usage statistics for the completion request.
  usage : @ai.Usage?
  message : @ai.Message
}
