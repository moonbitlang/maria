///|
struct Manager {
  path : String
  cache : @lru.Cache[String, Conversation]
}

///|
pub async fn Manager::new(path~ : String) -> Manager {
  let cache = @lru.cache(max_size=100)
  let conversations = @path.join(path, "conversations")
  if !@fs.exists(conversations) {
    @fs.make_directory(conversations)
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
