///|
/// Broadcast is a simple in-memory fan-out channel that keeps a history of
/// every value ever broadcast so new listeners can catch up before receiving
/// live updates. Each listener owns its own queue so slow consumers never block
/// faster ones.
struct Broadcast[T] {
  buffer : Array[T]
  listener : Array[@aqueue.Queue[T]?]
}

///|
/// Creates an empty broadcast with no buffered events or listeners.
pub fn[T] Broadcast::new() -> Broadcast[T] {
  { buffer: [], listener: [] }
}

///|
/// Appends `data` to the history buffer and enqueues it for every active
/// listener. The listener queues are unbounded, but we still guard against the
/// extremely unlikely case where a consumer cannot accept new items.
pub fn[T] Broadcast::put(self : Broadcast[T], data : T) -> Unit {
  self.buffer.push(data)
  for consumer in self.listener {
    if consumer is Some(queue) {
      guard queue.try_put(data) else {
        abort("Broadcast listener queue is full, cannot put data")
      }
    }
  }
}

///|
/// Registers a new listener by
/// 1. Creating an unbounded queue for future events,
/// 2. Cloning the current history so the listener can replay past events, and
/// 3. Running the supplied async callback with both pieces.
///
/// The listener slot is automatically cleared when the callback completes, so
/// subsequent subscribers can reuse it.
pub async fn[T, R] Broadcast::listen(
  self : Broadcast[T],
  f : async (ArrayView[T], @aqueue.Queue[T]) -> R,
) -> R {
  let aq = @aqueue.new(kind=Unbounded)
  let hist = self.buffer.copy()
  let i = for i in 0..<self.listener.length() {
    if self.listener[i] is None {
      self.listener[i] = Some(aq)
      break i
    }
  } else {
    let i = self.listener.length()
    self.listener.push(Some(aq))
    i
  }
  defer {
    self.listener[i] = None
  }
  f(hist, aq)
}
