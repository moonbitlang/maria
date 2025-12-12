///|
struct Conversation {
  clock : &@clock.Clock
  name : String
  description : String?
  id : String
  mut system_prompt : String?
  events : Array[@event.Event]
  created_at : Int64
  mut updated_at : Int64
  cwd : StringView
}

///|
pub fn Conversation::cwd(self : Conversation) -> StringView {
  self.cwd
}
