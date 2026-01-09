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
/// Gets the unique identifier of the conversation.
///
/// Parameters:
///
/// * `self` : The conversation instance.
///
/// Returns the UUID that uniquely identifies this conversation.
pub fn Conversation::id(self : Conversation) -> @uuid.Uuid {
  self.id
}

///|
/// Gets the name of the conversation.
///
/// Parameters:
///
/// * `self` : The conversation instance.
///
/// Returns the name assigned to this conversation as a string.
pub fn Conversation::name(self : Conversation) -> String {
  self.name
}

///|
/// Gets the creation timestamp of the conversation.
///
/// Parameters:
///
/// * `self` : The conversation instance.
///
/// Returns the Unix timestamp (in milliseconds) when the conversation was
/// created.
pub fn Conversation::created(self : Conversation) -> @clock.Timestamp {
  self.created_at
}

///|
/// Gets the last modification timestamp of the conversation.
///
/// Parameters:
///
/// * `self` : The conversation instance.
///
/// Returns the Unix timestamp (in milliseconds) when the conversation was last
/// updated.
pub fn Conversation::updated(self : Conversation) -> @clock.Timestamp {
  self.updated_at
}

///|
/// Retrieves all messages in the conversation as an array of AI messages.
///
/// Parameters:
///
/// * `self` : The conversation instance.
/// * `include_system` : Whether to include the system prompt message in the
///   returned array. Defaults to `true`.
///
/// Returns an array of `@ai.Message` objects representing the conversation
/// history. If `include_system` is `true` and a system prompt is set, the
/// system message will be the first element in the array, followed by the
/// chronological sequence of user messages, assistant messages, and tool
/// messages.
pub fn Conversation::messages(
  self : Conversation,
  include_system? : Bool = true,
) -> Array[@ai.Message] {
  let mut sys_msg = None
  let msgs = []
  for e in self.events() {
    match e.desc {
      SystemPromptSet(Some(prompt)) if include_system =>
        sys_msg = Some(@ai.system_message(content=prompt))
      SystemPromptSet(None) if include_system => sys_msg = None
      UserMessage(content) => msgs.push(@ai.user_message(content~))
      AssistantMessage(tool_calls~, content, ..) =>
        msgs.push(@ai.assistant_message(content~, tool_calls~))
      PostToolCall(tc, rendered~, ..) =>
        msgs.push(@ai.tool_message(tool_call_id=tc.id, content=rendered))
      _ => ()
    }
  }
  if sys_msg is Some(sys_msg) {
    [sys_msg, ..msgs]
  } else {
    msgs
  }
}

///|
/// Gets the current system prompt for the conversation.
///
/// Parameters:
///
/// * `self` : The conversation instance.
///
/// Returns `Some(prompt)` if a system prompt is set, or `None` if no system
/// prompt is configured.
pub fn Conversation::system_prompt(self : Conversation) -> String? {
  for e in self.events().rev_iter() {
    match e.desc {
      SystemPromptSet(prompt) => return prompt
      _ => ()
    }
  }
  None
}
