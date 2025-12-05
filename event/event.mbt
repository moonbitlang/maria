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
pub(all) struct ExternalEventQueue {
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
/// Event type that occurs during agent conversation lifecycle.
///
/// A typical conversation lifecycle looks like this:
///
/// ```moonbit no-check
/// // add system and user messages
/// MessageAdded (system)
/// MessageAdded (user)
/// // calling agent.start()
/// PreConversation
/// while true {
///   // poll external events
///   ExternalEventReceived (if any)
///   // count tokens before request
///   TokenCounted
///   // prune context if necessary
///   ContextPruned
///   // receive assistant response
///   RequestCompleted
///   // executing tool call
///   PreToolCall
///   PostToolCall
///   MessageAdded (tool)
///   // continue to iterate if there are more messages
/// }
/// // conversation ended
/// PostConversation
/// ```
pub(all) enum Event {
  /// Event triggered when a model is loaded.
  ModelLoaded(name~ : String, model~ : @model.Model)
  /// Event triggered before a conversation starts.
  PreConversation
  /// Event triggered after a conversation ends.
  PostConversation
  /// Event triggered when a new message is added to the conversation.
  ///
  /// **Note**: This event will be triggered for system/user/tool messages.
  /// This means it's very likely that you should do some filtering based on the
  /// message role. For example, If you are listening for both MessageAdded and
  /// PostToolCall events, you would probably receive duplicate contents, one in
  /// `MessageAdded` and another in `PostToolCall`, and you may want to ignore
  /// the `MessageAdded` event for tool messages.
  ///
  /// FIXME: emit this event for assistant messages as well.
  MessageAdded(@ai.Message)
  /// Event triggered when a message is unqueued from the pending queue.
  MessageUnqueued(id~ : @uuid.Uuid)
  /// Event triggered when a message is queued to be sent to the model.
  MessageQueued(id~ : @uuid.Uuid, @ai.Message)
  /// Event triggered when a tool is added to the agent. This message will only
  /// be triggered once per agent instance.
  ToolAdded(@tool.ToolDesc)
  /// Event triggered before a tool is called.
  PreToolCall(@ai.ToolCall)
  /// Event triggered after a tool call is completed.
  ///
  /// If you are interested in the result of the tool call, then this is the
  /// event you might want to listen for. Note you should not listen for
  /// MessageAdded for tool messages as the structural representation of tool
  /// call result will be lost.
  ///
  /// The `result` field can be used to determine whether the tool call was
  /// successful or not. `rendered` field is the string representation of the
  /// tool call result, which can be used for both human and LLM consumption.
  PostToolCall(@ai.ToolCall, result~ : Result[Json, Error], rendered~ : String)
  /// Event triggered when tokens are counted for a message or tool call.
  /// Tokens are counted in following scenarios:
  ///
  /// 1. Before a request is being sent, tokens are counted for all messages
  ///    in the conversation history to decide if to perform context pruning.
  /// 2. The context pruning algorithm may count token for multiple times to
  ///    determine when to stop.
  ///
  /// FIXME: Currently this event is triggered multiple times in a row.
  TokenCounted(Int)
  /// Event triggered when context pruning is performed.
  ///
  /// FIXME: Currently this event is triggered even if the context is with-in
  /// the limit and no pruning is performed.
  ContextPruned(origin_token_count~ : Int, pruned_token_count~ : Int)
  /// Event triggered when a chat completion request is completed.
  ///
  /// If you are interested in details in the assistant response, then this is
  /// the event you might want to listen for. Compared to `MessageAdded` event,
  /// this event contains more information like `usage` and `tool_calls`.
  RequestCompleted(usage~ : @ai.Usage?, message~ : @ai.Message)
  /// Event triggered when an external event is received and processed.
  ExternalEventReceived(ExternalEvent)
  /// Cancelled
  Cancelled
  /// Event triggered when the todo list is updated.
  TodoUpdated(Json)
}

///|
/// The central event dispatcher for agent lifecycle events.
///
/// `EventTarget` implements an observer pattern where multiple listeners can
/// subscribe to receive events. Events are queued and processed asynchronously,
/// ensuring that event emission is always non-blocking.
///
/// # Architecture
///
/// ```text
/// emit() ──▶ [Queue] ──▶ start() ──▶ [Listener 1]
///                               ──▶ [Listener 2]
///                               ──▶ [Listener N]
/// ```
///
/// # Threading Model
///
/// - `emit()` is synchronous and non-blocking (enqueues event)
/// - `start()` runs an async event loop that dispatches to listeners
/// - Listeners are invoked sequentially for each event
struct EventTarget {
  // TODO: Consider adding a `Closed` event variant instead of using `Event?`.
  // This would make the termination signal explicit in the type system rather
  // than using `None` as a sentinel value.
  queue : @aqueue.Queue[Event?]
  listeners : Array[async (Event) -> Unit]
}

///|
/// Creates a new `EventTarget` with an empty listener list.
///
/// The event target uses an unbounded queue to ensure `emit()` never blocks.
/// Remember to call `start()` in a background task to begin processing events.
///
/// # Returns
///
/// A new `EventTarget` instance ready to receive listeners and events.
///
/// # Example
///
/// ```moonbit no-check
/// let emitter = EventTarget::new()
/// emitter.add_listener(async fn(event) { println(event) })
/// // Start in background
/// spawn(() => emitter.start())
/// ```
pub fn EventTarget::new() -> EventTarget {
  EventTarget::{ queue: @aqueue.Queue::new(kind=Unbounded), listeners: [] }
}

///|
/// Emits an event to be processed by all registered listeners.
///
/// This method enqueues the event for asynchronous processing. The event will
/// be dispatched to all listeners when `start()` processes it from the queue.
///
/// # Parameters
///
/// - `event`: The `Event` to emit.
///
/// # Behavior
///
/// - **Non-blocking**: Returns immediately after enqueuing.
/// - **Order-preserving**: Events are processed in FIFO order.
///
/// # Panics
///
/// Aborts if the queue is full (should not happen with unbounded queue).
///
/// # Example
///
/// ```moonbit no-check
/// emitter.emit(PreConversation)
/// emitter.emit(TokenCounted(1500))
/// emitter.emit(PostConversation)
/// ```
pub fn EventTarget::emit(self : EventTarget, event : Event) -> Unit {
  guard self.queue.try_put(Some(event)) else {
    abort("Event queue is full, cannot emit event")
  }
}

///|
/// Registers an async listener function to receive events.
///
/// Listeners are called sequentially for each event in the order they were
/// registered. Each listener receives every event emitted after registration.
///
/// # Parameters
///
/// - `f`: An async function that takes an `Event` and returns `Unit`.
///
/// # Example
///
/// ```moonbit no-check
/// emitter.add_listener(async fn(event) {
///   match event {
///     PostToolCall(call, result~, rendered~) => {
///       // Log tool call results
///       println("Tool \(call.name) completed")
///     }
///     RequestCompleted(usage~, message~) => {
///       // Track token usage
///       if usage is Some(u) {
///         total_tokens += u.total_tokens
///       }
///     }
///     _ => ()
///   }
/// })
/// ```
pub fn EventTarget::add_listener(
  self : EventTarget,
  f : async (Event) -> Unit,
) -> Unit {
  self.listeners.push(f)
}

///|
/// Starts the event processing loop.
///
/// This async function runs continuously, waiting for events from the queue
/// and dispatching them to all registered listeners. It blocks until a `None`
/// sentinel is received (via `close()`).
///
/// # Behavior
///
/// - **Blocking**: Waits for events when queue is empty.
/// - **Sequential dispatch**: Listeners are called one at a time per event.
/// - **Terminates**: Exits when `close()` sends the termination signal.
///
/// # Usage
///
/// Should typically be spawned as a background task:
///
/// ```moonbit no-check
/// @async.with_task_group(fn(group) {
///   group.spawn_bg(fn() { emitter.start() }, no_wait=true)
///   // ... rest of the application
/// })
/// ```
pub async fn EventTarget::start(self : EventTarget) -> Unit {
  while self.queue.get() is Some(event) {
    for listener in self.listeners {
      listener(event)
    }
  }
}

///|
/// Immediately processes all pending events in the queue.
///
/// Unlike `start()`, this method does not wait for new events. It processes
/// all currently queued events and returns, making it useful for ensuring
/// all events are handled before a checkpoint.
///
/// # Behavior
///
/// - **Non-blocking on empty**: Returns immediately if queue is empty.
/// - **Draining**: Processes all pending events.
/// - **Does not terminate**: Does not affect the `start()` loop.
///
/// # Example
///
/// ```moonbit no-check
/// // Ensure all events are processed before saving state
/// emitter.flush()
/// save_checkpoint()
/// ```
pub async fn EventTarget::flush(self : EventTarget) -> Unit {
  while self.queue.try_get() is Some(Some(event)) {
    for listener in self.listeners {
      listener(event)
    }
  }
}

///|
/// Gracefully closes the event target.
///
/// This method:
/// 1. Flushes all remaining events (handling errors gracefully)
/// 2. Sends a termination signal (`None`) to stop the `start()` loop
///
/// # Error Handling
///
/// If any listener throws an error during the final flush, the error is
/// collected and re-raised after all events are processed. Only the first
/// error is propagated.
///
/// # Panics
///
/// Aborts if unable to enqueue the termination signal.
///
/// # Example
///
/// ```moonbit no-check
/// // Graceful shutdown
/// emitter.close()
/// // start() will now return
/// ```
pub async fn EventTarget::close(self : EventTarget) -> Unit {
  let errors = []
  while self.queue.try_get() is Some(Some(event)) {
    for listener in self.listeners {
      listener(event) catch {
        error => errors.push(error)
      }
    }
  }
  guard self.queue.try_put(None) else {
    abort("Event queue is full, cannot close")
  }
  if errors is [error, ..] {
    raise error
  }
}

///|
pub impl ToJson for Event with to_json(self : Event) -> Json {
  match self {
    ModelLoaded(name~, model~) =>
      {
        "msg": "ModelLoaded",
        "name": name.to_json(),
        "model": {
          let json = model.to_json()
          if json is Object(obj) {
            obj["api_key"] = "****"
            Json::object(obj)
          } else {
            json
          }
        },
      }
    TokenCounted(token_count) =>
      { "msg": "TokenCounted", "token_count": token_count }
    ContextPruned(origin_token_count~, pruned_token_count~) =>
      {
        "msg": "ContextPruned",
        "origin_token_count": origin_token_count,
        "pruned_token_count": pruned_token_count,
      }
    PreToolCall(tool_call) => {
      let tool_call = tool_call.to_openai()
      match tool_call.function.arguments {
        None =>
          {
            "msg": "PreToolCall",
            "tool_call": tool_call,
            "name": tool_call.function.name,
          }
        Some(arguments) =>
          try @json.parse(arguments) catch {
            error =>
              {
                "msg": "PreToolCall",
                "tool_call": tool_call,
                "name": tool_call.function.name,
                "args": tool_call.function.arguments,
                "error": error,
              }
          } noraise {
            args =>
              {
                "msg": "PreToolCall",
                "tool_call": tool_call,
                "name": tool_call.function.name,
                "args": args,
              }
          }
      }
    }
    PostToolCall(tool_call, result~, rendered~) => {
      let tool_call = tool_call.to_openai()
      match result {
        Ok(output) =>
          {
            "msg": "PostToolCall",
            "tool_call": tool_call,
            "name": tool_call.function.name,
            "result": output,
            "text": rendered,
          }
        Err(error) =>
          {
            "msg": "PostToolCall",
            "tool_call": tool_call,
            "name": tool_call.function.name,
            "error": error,
            "text": rendered,
          }
      }
    }
    PreConversation => { "msg": "PreConversation" }
    PostConversation => { "msg": "PostConversation" }
    MessageAdded(message) =>
      { "msg": "MessageAdded", "message": message.to_openai() }
    MessageQueued(id~, message) =>
      {
        "msg": "MessageQueued",
        "message": { "id": id, "message": message.to_openai() },
      }
    MessageUnqueued(id~) =>
      { "msg": "MessageUnqueued", "message": { "id": id } }
    ToolAdded(tool_desc) =>
      {
        "msg": "ToolAdded",
        "tool": {
          "name": tool_desc.name,
          "description": tool_desc.description,
          "schema": tool_desc.schema,
        },
      }
    RequestCompleted(usage~, message~) => {
      let usage = usage.map(fn(u) { u.to_openai() })
      let message = message.to_openai()
      { "msg": "RequestCompleted", "usage": usage, "message": message }
    }
    ExternalEventReceived(external_event) =>
      { "msg": "ExternalEventReceived", "event": external_event.to_json() }
    Cancelled => { "msg": "MariaCancelled" }
    TodoUpdated(todo) => { "msg": "TodoUpdated", "todo": todo.to_json() }
  }
}

///|
pub impl ToJson for ExternalEvent with to_json(self : ExternalEvent) -> Json {
  match self {
    Diagnostics(diagnostics) =>
      { "type": "Diagnostics", "diagnostics": diagnostics.to_json() }
    UserCancellation => { "type": "UserCancellation" }
    UserMessage(message) => { "type": "UserMessage", "message": message }
  }
}
