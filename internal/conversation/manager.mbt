///|
struct Manager {
  uuid : @uuid.Generator
  clock : &@clock.Clock
  cwd : StringView
  cache : @lru.Cache[String, Conversation]
}

///|
pub async fn Manager::new(
  uuid~ : @uuid.Generator,
  clock? : &@clock.Clock = @clock.epoch,
  cwd~ : StringView,
) -> Manager {
  let cache = @lru.cache(max_size=100)
  let conversations = cwd
    |> @path.join(".moonagent")
    |> @path.join("conversations")
  if !@fsx.exists(conversations) {
    @fsx.make_directory(conversations, recursive=true, exists_ok=true)
  }
  Manager::{ uuid, clock, cwd, cache }
}

///|
pub async fn Manager::load(self : Manager, id : String) -> Conversation? {
  let id = id
  if self.cache.get(id) is Some(id) {
    return Some(id)
  }
  let path = self.cwd
    |> @path.join(".moonagent")
    |> @path.join("conversations")
    |> @path.join("\{id}.json")
  if !@fsx.exists(path) {
    return None
  }
  let conversation = @fsx.read_file(path) |> @json.parse() |> @json.from_json()
  self.cache[id] = conversation
  Some(conversation)
}

///|
pub async fn Manager::save(self : Manager, conversation : Conversation) -> Unit {
  let path = self.cwd
    |> @path.join(".moonagent")
    |> @path.join("conversations")
    |> @path.join("\{conversation.id}.json")
  let dir = @path.dirname(path)
  @fsx.make_directory(dir, recursive=true, exists_ok=true)
  let json = conversation.to_json()
  @fsx.write_to_file(path, json.stringify(indent=2))
}

///|
pub async fn Manager::list(self : Manager) -> Array[String] {
  let path = self.cwd |> @path.join(".moonagent") |> @path.join("conversations")
  let entries = @fsx.list_directory(path)
  let ids = []
  // CR: if we are going to implement list comprehension
  // we may need support continue/break keywords
  // [for x in xs if condition => { continue else ...}]
  for entry in entries {
    if entry is { kind: Regular, name: [.., .. ".json"] as name, .. } {
      try @uuid.parse(@path.stem(name)) catch {
        _ => continue
      } noraise {
        id => ids.push(id.to_string())
      }
    }
  }
  ids
}

///|
pub fn Manager::new_conversation(
  self : Manager,
  name~ : String,
  description? : String,
) -> Conversation {
  {
    clock: self.clock,
    name,
    description,
    id: self.uuid.v4().to_string(),
    messages: [],
    created_at: self.clock.now(),
    updated_at: self.clock.now(),
  }
}
