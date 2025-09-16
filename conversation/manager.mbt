///|
priv struct Manager {
  storage_path : String
  mut id : String
  cache : @lru.Cache[String, Conversation]
}

///|
let manager : Manager = {
  let cache = @lru.cache(max_size=100)
  Manager::{
    storage_path: ".moonagent/conversations",
    id: @uuid.v4().to_string(),
    cache,
  }
}

///|
async fn Manager::load_conversation(
  self : Manager,
  id? : String = self.id,
) -> Conversation? raise {
  if self.cache.get(id) is Some(id) {
    return Some(id)
  }
  let path = self.storage_path
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
async fn Manager::list_conversation_ids(self : Manager) -> Array[String] raise {
  let path = self.storage_path |> @path.join("conversations")
  let ids = []
  for entry in @fs.list_directory(path) {
    if entry is [.. id, .. ".json"] {
      ids.push(id.to_string())
    }
  }
  ids
}

///|
pub async fn list(
  limit? : Int = 100,
  sort_by? : (Conversation, Conversation) -> Int,
) -> Array[Conversation] raise {
  let ids = manager.list_conversation_ids()
  let conversations = []
  for id in ids {
    match manager.load_conversation(id~) {
      Some(conversation) => conversations.push(conversation)
      None => continue
    }
    if conversations.length() >= limit {
      break
    }
  }
  let sort_by = match sort_by {
    Some(sort_by) => sort_by
    None => (a, b) => (b.updated_at - a.updated_at).to_int()
  }
  conversations.sort_by(sort_by)
  conversations
}

///|
async fn Manager::save_conversation(
  self : Manager,
  conversation : Conversation,
) -> Unit raise {
  let path = self.storage_path
    |> @path.join("conversations")
    |> @path.join("\{conversation.id}.json")
  let dir = @path.dirname(path)
  @fs.make_directory(dir, recursive=true)
  let json = conversation.to_json()
  @fs.write_to_file(path, json.stringify(indent=2))
}

///|
pub async fn create(
  name~ : String,
  description? : String,
) -> Conversation raise {
  let conversation = Conversation::new(name~, description?)
  manager.save_conversation(conversation)
  manager.cache[conversation.id] = conversation
  manager.id = conversation.id
  conversation
}

///|
pub fn switch_to(conversation : Conversation) -> Unit {
  manager.id = conversation.id
}

///|
pub async fn current() -> Conversation? raise {
  manager.load_conversation()
}

///|
pub async fn Conversation::add_message(
  self : Conversation,
  message : @openai.ChatCompletionMessageParam,
  usage? : @openai.CompletionUsage,
  created? : Int64,
) -> Unit raise {
  let timestamp = match created {
    None => @uv.clock_gettime(Realtime).sec()
    Some(created) => created
  }
  let message = Message::{ timestamp, usage, message }
  self.messages.push(message)
  self.updated_at = @uv.clock_gettime(Realtime).sec()
  manager.save_conversation(self)
}

///|
async fn Manager::initialize(self : Manager) -> Unit {
  let path = self.storage_path |> @path.join("conversations")
  @fs.make_directory(path, recursive=true)
}

///|
pub async fn initialize() -> Unit {
  manager.initialize()
}
