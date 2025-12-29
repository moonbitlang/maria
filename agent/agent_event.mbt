///|
/// Emits an event and logs it to the agent's logger.
///
/// This function serves as the central event dispatcher for the agent. It both
/// emits events through the event target (for registered listeners) and logs
/// them using the agent's logger for persistent recording.
///
/// Each event type is logged with appropriate structured data:
/// * `TokenCounted` - Logs the token count for the current request
/// * `ContextPruned` - Logs before/after token counts (only if pruning occurred)
/// * `PreToolCall` - Logs tool name and parsed arguments
/// * `PostToolCall` - Logs tool result or error with rendered text
/// * `PreConversation` - Logs conversation start
/// * `PostConversation` - Logs conversation end
/// * `UserMessage` - Logs the added message
/// * `ToolAdded` - Logs tool descriptor (name, description, schema)
/// * `AssistantMessage` - Logs API usage and response message
///
/// Parameters:
///
/// * `agent` : The agent instance emitting the event.
/// * `event` : The event to emit and log.
fn Agent::emit(
  agent : Agent,
  event : @event.EventDesc,
  id? : @uuid.Uuid,
) -> Unit {
  let id = id.unwrap_or_else(() => agent.uuid.v4())
  agent.event_target.put({ id, desc: event })
}

///|
/// Registers an event listener for the specified event type on the agent.
///
/// Parameters:
///
/// * `agent` : The agent to add the event listener to.
/// * `f` : The asynchronous callback function to execute when the event is
///   triggered. The function receives an `Event` containing relevant
///   event data.
pub fn Agent::add_listener(
  agent : Agent,
  f : async (@event.Event) -> Unit,
) -> Unit {
  agent.event_target.add_listener(f)
}

///|
/// Returns the external events queue for this agent.
///
/// The environment can use this queue to send events to the agent:
/// * `Cancelled` - to cancel the current operation
/// * `UserMessage` - to send an immediate message that interrupts the flow
/// * `Diagnostics` - to provide IDE diagnostic information
///
/// Example:
/// ```moonbit no-check
/// let queue = agent.external_events()
/// queue.send(UserMessage("Please stop and focus on this instead"))
/// ```
pub fn Agent::external_events(self : Agent) -> @event.ExternalEventQueue {
  self.external_events
}
