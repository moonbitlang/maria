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
