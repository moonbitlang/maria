///|
struct Todo {
  config : Config
  mut items : Items
  event_target : @event.EventTarget?
}

///|
priv struct Config {
  uuid : @uuid.Generator
  clock : &@clock.Clock
  cwd : String
}

///|
priv struct Items {
  todos : Array[Item]
  created_at : String
  mut updated_at : String
} derive(ToJson, FromJson, Eq)

///|
priv enum Priority {
  High
  Medium
  Low
} derive(ToJson, FromJson, Show, Eq)

///|
priv enum Status {
  Pending
  InProgress
  Completed
} derive(ToJson, FromJson, Show, Eq)

///|
priv struct Item {
  content : String
  created_at : String
  id : String
  notes : String?
  priority : Priority
  status : Status
  updated_at : String
} derive(ToJson, FromJson, Eq)
