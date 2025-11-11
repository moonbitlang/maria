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
      queue.put(data)
    }
  }
}

///|
pub async fn[T, R] Broadcast::listen(
  self : Broadcast[T],
  f : async (@aqueue.Queue[T]) -> R,
) -> R {
  let aqueue = @aqueue.new()
  for event in self.buffer {
    aqueue.put(event)
  }
  let index = for i in 0..<self.listener.length() {
    if self.listener[i] is None {
      self.listener[i] = Some(aqueue)
      break i
    }
  } else {
    let index = self.listener.length()
    self.listener.push(Some(aqueue))
    index
  }
  let value = f(aqueue)
  self.listener[index] = None
  value
}
