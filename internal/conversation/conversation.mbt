///|
pub fn Conversation::add_event(
  self : Conversation,
  event : @event.Event,
) -> Unit {
  let now = self.clock.now()
  self.events.push(event)
  self.updated_at = now
}

///|
pub fn Conversation::add_events(
  self : Conversation,
  events : ArrayView[@event.Event],
) -> Unit {
  let now = self.clock.now()
  for event in events {
    self.events.push(event)
  }
  self.updated_at = now
}

///|
pub fn Conversation::id(self : Conversation) -> String {
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
  for e in self.events {
    match e {
      Outgoing(MessageAdded(message)) => msgs.push(message)
      Outgoing(RequestCompleted(message~, ..)) => msgs.push(message)
      _ => ()
    }
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
