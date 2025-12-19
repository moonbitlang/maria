///|
pub fn Conversation::add_message(
  self : Conversation,
  message : @ai.Message,
  usage? : @ai.Usage,
) -> Unit {
  let now = self.clock.now()
  let message = Message::{ timestamp: now, usage, message }
  self.messages.push(message)
  self.updated_at = now
}

///|
pub fn Conversation::add_messages(
  self : Conversation,
  messages : Array[@ai.Message],
) -> Unit {
  for message in messages {
    self.add_message(message)
  }
}

///|
pub fn Conversation::id(self : Conversation) -> @uuid.Uuid {
  self.id
}

///|
pub fn Conversation::messages(
  self : Conversation,
  include_system? : Bool = true,
) -> Array[@ai.Message] {
  let msgs = []
  if include_system && self.system_prompt is Some(system_prompt) {
    msgs.push(@ai.system_message(content=system_prompt))
  }
  for m in self.messages {
    msgs.push(m.message)
  }
  msgs
}

///|
pub fn Conversation::system_prompt(self : Conversation) -> String? {
  self.system_prompt
}

///|
pub fn Conversation::set_system_prompt(
  self : Conversation,
  prompt : String?,
) -> Unit {
  self.system_prompt = prompt
}
