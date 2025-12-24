///|
/// Broadcast is a simple in-memory fan-out channel that keeps a history of
/// every value ever broadcast so new listeners can catch up before receiving
/// live updates. Listeners share a single history buffer and each tracks its
/// own read index, so slow consumers do not block faster ones from making
/// progress, but can increase memory usage because values are kept until all
/// listeners have consumed them.
struct Broadcast[T] {
  /// History of all broadcasted values.
  values : Array[T]
  /// Conditional variable to signal new incoming values.
  read : @cond_var.Cond
  /// Registered listeners that will process incoming values. We store both the
  /// current index in the history and the async function because we want to
  /// "remember" where the function last left off.
  readers : Array[Reader[T]]
}

///|
priv struct Reader[T] {
  mut index : Int
  f : async (T) -> Unit
}

///|
/// Creates an empty broadcast with no buffered events or listeners.
pub fn[T] Broadcast::new() -> Broadcast[T] {
  { values: [], read: @cond_var.Cond::new(), readers: [] }
}

///|
/// Appends `data` to the history buffer and notifies all waiting readers that a
/// new value is available.
pub fn[T] Broadcast::put(self : Broadcast[T], data : T) -> Unit {
  self.values.push(data)
  self.read.broadcast()
}

///|
/// Reads a value from the broadcast history at the specified index, blocking
/// until the value becomes available.
///
/// Parameters:
///
/// * `self` : The broadcast instance to read from.
/// * `index` : The zero-based position in the broadcast history to read from.
///
/// Returns the value at the specified index in the broadcast history.
pub async fn[T] Broadcast::read(self : Broadcast[T], index : Int) -> T {
  loop self.values.get(index) {
    Some(value) => return value
    None => {
      self.read.wait()
      continue self.values.get(index)
    }
  }
}

///|
/// Registers a new asynchronous listener that will process all broadcasted
/// values.
///
/// Parameters:
///
/// * `self` : The broadcast instance to add the listener to.
/// * `f` : The asynchronous function that will be called for each broadcasted
///   value.
/// * `include_history` : Whether the listener should receive all previously
///   broadcasted values before receiving new ones. Defaults to `true`.
pub fn[T] Broadcast::add_listener(
  self : Broadcast[T],
  include_history? : Bool = true,
  f : async (T) -> Unit,
) -> Unit {
  let initial = if include_history { 0 } else { self.values.length() }
  self.readers.push(Reader::{ index: initial, f })
}

///|
/// Inspect and retrieve all broadcasted values in a read-only view.
///
/// Parameters:
///
/// * `self` : The broadcast channel to retrieve values from.
///
/// Returns an array containing all values that have been previously broadcast,
/// in the order they were added.
pub fn[T] Broadcast::values(self : Broadcast[T]) -> ArrayView[T] {
  self.values
}

///|
/// Control handle for a running broadcast session that allows graceful
/// shutdown.
struct Session {
  stop : @cond_var.Cond
}

///|
/// Signals all waiting tasks in the broadcast system to stop gracefully.
///
/// Parameters:
///
/// * `self` : The session to stop.
pub fn Session::stop(self : Session) -> Unit {
  self.stop.broadcast()
}

///|
/// A simple barrier synchronization primitive that allows multiple tasks to
/// wait until a specified number of arrivals have occurred.
priv struct Barrier {
  mut count : Int
  target : Int
  cond : @cond_var.Cond
}

///|
fn Barrier::new(target : Int) -> Barrier {
  { count: 0, target, cond: @cond_var.Cond::new() }
}

///|
/// Waits at the barrier until the target number of waiters have arrived.
async fn Barrier::wait(self : Barrier) -> Unit {
  while self.count < self.target {
    self.cond.wait()
  }
}

///|
/// Signals arrival at the barrier, potentially waking up waiters if the target
/// number has been reached.
fn Barrier::arrive(self : Barrier) -> Unit {
  // Because MoonBit is a single-threaded runtime, we don't need to worry about
  // atomic increments here. As long as we don't yield here, we can "treat"
  // this as atomic.
  self.count += 1
  if self.count >= self.target {
    self.cond.broadcast()
  }
}

///|
/// Starts the broadcast system by spawning background tasks for all registered
/// listeners to process incoming values asynchronously.
///
/// Parameters:
///
/// * `self` : The broadcast instance whose listeners will be started.
pub async fn[T, G] Broadcast::spawn_in(
  self : Broadcast[T],
  group : @async.TaskGroup[G],
) -> Session {
  let stop = @cond_var.Cond::new()
  // Works even if there are no readers. Consider:
  // 1. There is no reader, which means self.readers.length() == 0
  // 2. There will be no calls to Barrier::arrive, so the count will remain 0
  // 3. When we call Barrier::wait, the condition is already satisfied (0 >= 0)
  let start = Barrier::new(self.readers.length())
  group.spawn_bg(
    () => {
      group.add_defer(() => self.flush())
      @async.with_task_group(group => {
        for reader in self.readers {
          group.spawn_bg(
            () => {
              start.arrive()
              for {
                let index = reader.index
                let value = self.read(index)
                // It is possible that other coroutines have already processed
                // this value (using flush), so we need to check the index
                // again.
                if index == reader.index {
                  (reader.f)(value)
                  reader.index = index + 1
                }
              }
            },
            allow_failure=true,
          )
        }
        group.spawn_bg(
          () => {
            stop.wait()
            group.return_immediately(())
          },
          no_wait=true,
        )
      })
    },
    allow_failure=true,
  )
  start.wait()
  { stop, }
}

///|
/// Processes all pending values for all registered listeners synchronously.
///
/// Parameters:
///
/// * `self` : The broadcast to flush.
pub async fn[T] Broadcast::flush(self : Broadcast[T]) -> Unit {
  let errors = []
  for reader in self.readers {
    try {
      while self.values.get(reader.index) is Some(value) {
        (reader.f)(value)
        reader.index += 1
      }
    } catch {
      error => errors.push(error)
    }
  }
  // Re-raise any errors that occurred during processing. Note that we don't
  // aggregate them: aggregating them makes it harder to pattern-match on
  // specific error, and only the first error will be surfaced while any
  // subsequent errors are discarded.
  for error in errors {
    raise error
  }
}

///|
/// Listens to all broadcasted values from the beginning, processing each value
/// sequentially with the provided handler function.
///
/// Parameters:
///
/// * `self` : The broadcast channel to listen to.
/// * `include_history` : Whether to include all previously broadcasted values
///   before processing new ones. Defaults to `true`.
/// * `f` : The asynchronous function that will be called for each broadcasted
///   value in order.
///
/// Never returns. Note that calling `Session::stop` WON'T stop this listener.
pub async fn[T] Broadcast::listen_forever(
  self : Broadcast[T],
  include_history? : Bool = true,
  f : async (T) -> Unit,
) -> Unit {
  let initial = if include_history { 0 } else { self.values.length() }
  for i = initial; ; i = i + 1 {
    let event = self.read(i)
    f(event)
  }
}
