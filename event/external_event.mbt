///|
/// External events that can be sent to the agent from outside sources.
/// These events are collected via polling and can influence the conversation.
pub(all) enum ExternalEvent {
  /// Diagnostics from IDE (errors, warnings from the problems panel)
  Diagnostics(@diagnostics.Diagnostics)
  /// User wants to cancel the current operation
  UserCancellation
  /// User sends an immediate message (interrupting current flow)
  UserMessage(String)
  /// Sets the system prompt for the conversation
  SetSystemPrompt(String)
  /// Clears the system prompt for the conversation
  ClearSystemPrompt
  /// Sets the enabled tools for the agent
  SetEnabledTools(Set[String])
}

///|
/// A queue for receiving external events from the environment.
///
/// The `ExternalEventQueue` provides a thread-safe, non-blocking mechanism for
/// external sources (IDE, user input, environment) to communicate with the agent.
/// The environment pushes events via `send()`, and the agent polls via `poll()`.
///
/// # Example
///
/// ```moonbit no-check
/// let queue = ExternalEventQueue::new()
///
/// // From external source (e.g., IDE integration)
/// queue.send(Diagnostics(diagnostics))
///
/// // From agent (polling during conversation)
/// let events = queue.poll() // Returns all pending events
/// ```
struct ExternalEventQueue {
  queue : @aqueue.Queue[ExternalEvent]
}

///|
/// Creates a new `ExternalEventQueue` with an unbounded async queue.
///
/// The queue is unbounded to prevent blocking when external sources send events,
/// ensuring that event producers never need to wait.
///
/// # Returns
///
/// A new `ExternalEventQueue` instance ready to receive events.
pub fn ExternalEventQueue::new() -> ExternalEventQueue {
  ExternalEventQueue::{ queue: @aqueue.Queue::new(kind=Unbounded) }
}

///|
/// Sends an external event to the agent.
///
/// This method is designed to be called from external contexts (environment,
/// IDE integration, user input handlers) to communicate with the agent.
///
/// # Parameters
///
/// - `event`: The `ExternalEvent` to send to the agent.
///
/// # Behavior
///
/// - **Non-blocking**: Returns immediately without waiting.
/// - **Thread-safe**: Can be safely called from any context.
/// - **Fire-and-forget**: Silently ignores failures (queue full scenario).
///
/// # Example
///
/// ```moonbit no-check
/// // Send IDE diagnostics
/// queue.send(Diagnostics(diagnostics))
///
/// // Request cancellation
/// queue.send(UserCancellation)
///
/// // Send user message
/// queue.send(UserMessage("Stop and explain"))
/// ```
pub fn ExternalEventQueue::send(
  self : ExternalEventQueue,
  event : ExternalEvent,
) -> Unit {
  guard self.queue.try_put(event) else { return }
}

///|
/// Polls and retrieves all pending external events from the queue.
///
/// This method is called by the agent to check for and process any external
/// events that have been sent since the last poll. It drains the queue,
/// returning all accumulated events.
///
/// # Returns
///
/// An `Array[ExternalEvent]` containing all pending events. Returns an empty
/// array if no events are pending.
///
/// # Behavior
///
/// - **Non-blocking**: Returns immediately with available events.
/// - **Draining**: Removes all events from the queue.
/// - **Order-preserving**: Events are returned in FIFO order.
///
/// # Example
///
/// ```moonbit no-check
/// // During conversation loop
/// let external_events = queue.poll()
/// for event in external_events {
///   match event {
///     UserCancellation => return // Stop conversation
///     Diagnostics(d) => process_diagnostics(d)
///     UserMessage(msg) => handle_message(msg)
///   }
/// }
/// ```
pub fn ExternalEventQueue::poll(
  self : ExternalEventQueue,
) -> Array[ExternalEvent] {
  let events = []
  while self.queue.try_get() is Some(event) {
    events.push(event)
  }
  events
}

///|
pub impl ToJson for ExternalEvent with to_json(self : ExternalEvent) -> Json {
  match self {
    Diagnostics(diagnostics) =>
      { "type": "Diagnostics", "diagnostics": diagnostics.to_json() }
    UserCancellation => { "type": "UserCancellation" }
    UserMessage(message) => { "type": "UserMessage", "message": message }
    SetSystemPrompt(prompt) => { "type": "SetSystemPrompt", "prompt": prompt }
    ClearSystemPrompt => { "type": "ClearSystemPrompt" }
    SetEnabledTools(tool_names) =>
      { "type": "SetEnabledTools", "tool_names": tool_names.to_json() }
  }
}
