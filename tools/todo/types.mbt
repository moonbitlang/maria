///|
struct Todo {
  config : Config
  mut items : Items
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
} derive(ToJson, FromJson)

///|
priv enum Priority {
  High
  Medium
  Low
} derive(ToJson, FromJson, Show)

///|
priv enum Status {
  Pending
  InProgress
  Completed
} derive(ToJson, FromJson, Show)

///|
priv struct Item {
  content : String
  created_at : String
  id : String
  notes : String?
  priority : Priority
  status : Status
  updated_at : String
} derive(ToJson, FromJson)
