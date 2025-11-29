///|
priv type Object

///|
fn[T] Object::of(value : T) -> Object = "%identity"

///|
fn[T] Object::to(self : Object) -> T = "%identity"

///|
struct Event {
  object : Object
  to_json : &ToJson
}

///|
let event_id : Int64 = id_to_int64(Event::id)

///|
pub fn[T : Type] Event::of(value : T) -> Event {
  Event::{ object: Object::of(value), to_json: value }
}

///|
pub fn[T : Type] Event::to(self : Event) -> T {
  ignore(T::id)
  self.object.to()
}

///|
pub impl ToJson for Event with to_json(self : Event) -> Json {
  self.to_json.to_json()
}

///|
pub(open) trait Type: ToJson {
  id() -> Unit = _
}

///|
impl Type with id() -> Unit {

}

///|
pub impl Type for Event

///|
fn id_to_int64(id : () -> Unit) -> Int64 = "%i32_to_i64"

///|
struct EventTarget {
  queue : @aqueue.Queue[(Int64, Event)]
  listeners : Map[Int64, Array[async (Object) -> Unit]]
  defaults : Array[async (Event) -> Unit]
}

///|
pub fn EventTarget::new() -> EventTarget {
  EventTarget::{
    queue: @aqueue.Queue::new(kind=Unbounded),
    listeners: {},
    defaults: [],
  }
}

///|
pub fn[T : Type] EventTarget::emit(self : EventTarget, event : T) -> Unit {
  let id = id_to_int64(T::id)
  guard self.queue.try_put((id, Event::of(event))) else {
    abort("Event queue is full, cannot emit event")
  }
}

///|
pub let default_target : EventTarget = EventTarget::new()

///|
pub fn[T : Type] EventTarget::add_listener(
  self : EventTarget,
  f : async (T) -> Unit,
) -> Unit {
  let id = id_to_int64(T::id)
  if id == event_id {
    self.defaults.push((event : Event) => f(Object::of(event).to()))
  } else {
    let of : async (Object) -> Unit = o => f(o.to())
    let fs = match self.listeners.get(id) {
      None => {
        let fs = []
        self.listeners[id] = fs
        fs
      }
      Some(fs) => fs
    }
    fs.push(of)
  }
}

///|
pub async fn EventTarget::start(self : EventTarget) -> Unit {
  while true {
    let (id, event) = self.queue.get()
    if self.listeners.get(id) is Some(fs) {
      for f in fs {
        f(event.object)
      }
    }
    for f in self.defaults {
      f(event)
    }
  }
}
