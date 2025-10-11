///|
struct Target[T] {
  aqueue : @aqueue.Queue[T?]
  listeners : Array[async (T) -> Unit]
}

///|
pub fn[T] Target::new() -> Target[T] {
  Target::{ aqueue: @aqueue.Queue::new(), listeners: [] }
}

///|
pub fn[T] Target::emit(self : Target[T], event : T) -> Unit {
  self.aqueue.put(Some(event))
}

///|
pub fn[T] Target::add_listener(
  self : Target[T],
  f : async (T) -> Unit,
) -> Unit noraise {
  self.listeners.push(f)
}

///|
pub async fn[T] Target::start(self : Target[T]) -> Unit {
  loop self.aqueue.get() {
    Some(event) => {
      for listener in self.listeners {
        listener(event)
      }
      continue self.aqueue.get()
    }
    None => break
  }
}

///|
pub fn[T] Target::close(self : Target[T]) -> Unit {
  self.aqueue.put(None)
}
