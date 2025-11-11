///|
priv struct Broadcast[T] {
  history : Array[T]
  consumers : Array[@aqueue.Queue[T]?]
}

///|
fn[T] Broadcast::new() -> Broadcast[T] {
  { history: [], consumers: [] }
}

///|
fn[T] Broadcast::put(self : Broadcast[T], data : T) -> Unit {
  self.history.push(data)
  for consumer in self.consumers {
    if consumer is Some(queue) {
      queue.put(data)
    }
  }
}

///|
async fn[T] Broadcast::get(self : Broadcast[T]) -> T {
  let aqueue = @aqueue.new()
  let index = for i in 0..<self.consumers.length() {
    if self.consumers[i] is None {
      self.consumers[i] = Some(aqueue)
      break i
    }
  } else {
    let index = self.consumers.length()
    self.consumers.push(Some(aqueue))
    index
  }
  let value = aqueue.get()
  self.consumers[index] = None
  value
}
