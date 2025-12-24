///|
struct Conversation {
  clock : &@clock.Clock
  name : String
  description : String?
  id : @uuid.Uuid
  mut system_prompt : String?
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
