///|
struct Manager {
  path : String
  cache : @lru.Cache[String, Conversation]
}

///|
pub async fn Manager::new(path~ : String) -> Manager {
  let cache = @lru.cache(max_size=100)
  let conversations = @path.join(path, "conversations")
  println("Conversation path: \{conversations}")
  if !@fs.exists(conversations) {
    @fs.make_directory(conversations, recursive=true)
  }
  Manager::{ path, cache }
}

///|
pub async fn Manager::load(self : Manager, id : Id) -> Conversation? {
  let id = id.0
  if self.cache.get(id) is Some(id) {
    return Some(id)
  }
  let path = self.path
    |> @path.join("conversations")
    |> @path.join("\{id}.json")
  if !@fs.exists(path) {
    return None
  }
  let conversation = @fs.read_file(path) |> @json.parse() |> @json.from_json()
  self.cache[id] = conversation
  Some(conversation)
}

///|
pub async fn Manager::save(self : Manager, conversation : Conversation) -> Unit {
  let path = self.path
    |> @path.join("conversations")
    |> @path.join("\{conversation.id}.json")
  let dir = @path.dirname(path)
  @fs.make_directory(dir, recursive=true)
  let json = conversation.to_json()
  @fs.write_to_file(path, json.stringify(indent=2))
}

///|
pub async fn Manager::list(self : Manager) -> Array[Id] {
  let path = self.path |> @path.join("conversations")
  let entries = @fs.list_directory(path)
  let ids = []
  for entry in entries {
    if !(entry.kind is Regular) {
      continue
    }
    if !entry.name.has_suffix(".json") {
      continue
    }
    let id = @uuid.parse(@path.stem(entry.name)) catch { _ => continue }
    ids.push(Id(id.to_string()))
  }
  ids
}
