///|
struct Broadcast[T] {
  buffer : Array[T]
  listener : Array[@aqueue.Queue[T]?]
}

///|
pub fn[T] Broadcast::new() -> Broadcast[T] {
  { buffer: [], listener: [] }
}

///|
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
