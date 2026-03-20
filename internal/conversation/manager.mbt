///|
using @path {type Path}

///|
struct Manager {
  logger : @pino.Logger
  uuid : @uuid.Generator
  clock : &@clock.Clock
  home : StringView
  cache : @lru.Cache[@uuid.Uuid, Conversation]
}

///|
pub async fn Manager::new(
  uuid~ : @uuid.Generator,
  clock? : &@clock.Clock = @clock.epoch,
  home~ : StringView,
  logger? : @pino.Logger = @pino.logger(
    "conversation_manager",
    @pino.Transport::console(),
  ),
) -> Manager {
  let cache = @lru.cache(max_size=100)
  let conversations = Path::join(home.to_string(), ".moonagent")
    .join("conversations")
    .to_string()
  if !@fsx.exists(conversations) {
    @fsx.make_directory(conversations, recursive=true, exists_ok=true)
  }
  Manager::{ uuid, clock, home, cache, logger }
}

///|
pub async fn Manager::load(self : Manager, id : @uuid.Uuid) -> Conversation? {
  if self.cache.get(id) is Some(id) {
    return Some(id)
  }
  let path = Path::join(self.home.to_string(), ".moonagent")
    .join("conversations")
    .join("\{id}.json")
    .to_string()
  if !@fsx.exists(path) {
    self.logger.warn(
      "Conversation with id '\{id}' does not exist at path '\{path}'",
    )
    return None
  }
  let conversation = (@fsx.read_file(path) |> @json.parse() |> @json.from_json()) catch {
    error =>
      if @async.is_being_cancelled() {
        raise error
      } else {
        self.logger.warn("Failed to load conversation from '\{path}': \{error}")
        return None
      }
  }
  self.cache[id] = conversation
  Some(conversation)
}

///|
pub async fn Manager::save(self : Manager, conversation : Conversation) -> Unit {
  let path = Path::join(self.home.to_string(), ".moonagent")
    .join("conversations")
    .join("\{conversation.id}.json")
    .to_string()
  let dir = Path::dirname(path).to_string()
  @fsx.make_directory(dir, recursive=true, exists_ok=true)
  let json = conversation.to_json()
  @fsx.write_to_file(path, json.stringify(indent=2))
}

///|
pub async fn Manager::list(self : Manager) -> Array[@uuid.Uuid] {
  let path = Path::join(self.home.to_string(), ".moonagent")
    .join("conversations")
    .to_string()
  let entries = @fsx.list_directory(path)
  let ids = []
  // CR: if we are going to implement list comprehension
  // we may need support continue/break keywords
  // [for x in xs if condition => { continue else ...}]
  for entry in entries {
    if entry is { kind: Regular, name: [.. name, .. ".json"], .. } {
      try @uuid.parse(name) catch {
        _ => continue
      } noraise {
        id => ids.push(id)
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
  cwd~ : String,
  web_search? : Bool = false,
) -> Conversation {
  {
    clock: self.clock,
    name,
    description,
    id: self.uuid.v4(),
    created_at: self.clock.now(),
    updated_at: self.clock.now(),
    cwd,
    events: [],
    web_search,
  }
}
