///|
pub fn Conversation::display(
  self : Conversation,
  show_messages? : Bool = false,
) -> Array[String] {
  let lines = []
  if self.name is Some(name) {
    lines.push("Name: \{name}")
  }
  if self.description is Some(description) {
    lines.push("Description: \{description}")
  }
  if show_messages {
    for i, message in self.messages {
      let message = message.message
      match message {
        Assistant(content, ..) => {
          lines.push("\{i}. [assistant]")
          content.split("\n").each(line => lines.push("  \{line}"))
        }
        User(content) => {
          lines.push("\{i}. [user]")
          content.split("\n").each(line => lines.push("  \{line}"))
        }
        System(content) => {
          lines.push("\{i}. [system]")
          content.split("\n").each(line => lines.push("  \{line}"))
        }
        Tool(content, ..) => {
          lines.push("\{i}. [tool]")
          content.split("\n").each(line => lines.push("  \{line}"))
        }
      }
    }
  } else {
    lines.push("Messages: \{self.messages.length()}")
  }
  fn show_time(ts : Int64) -> String {
    try @time.unix(ts / 1000) catch {
      _ => return "invalid time".to_string()
    } noraise {
      t => t.to_string()
    }
  }

  lines.push("Created: \{show_time(self.created_at)}")
  lines.push("Updated: \{show_time(self.updated_at)}")
  lines
}

///|
pub impl ToJson for Conversation with to_json(self : Conversation) -> Json {
  fn int64_to_json(value : Int64) -> Json {
    Json::number(value.to_double(), repr=value.to_string())
  }

  let object : Map[String, Json] = { "id": self.id }
  if self.name is Some(name) {
    object["name"] = name.to_json()
  }
  if self.system_prompt is Some(system_prompt) {
    object["system_prompt"] = system_prompt.to_json()
  }
  object["messages"] = self.messages.to_json()
  object["created_at"] = int64_to_json(self.created_at).to_json()
  object["updated_at"] = int64_to_json(self.updated_at).to_json()
  if self.description is Some(description) {
    object["description"] = description.to_json()
  }
  object.to_json()
}

///|
pub impl @json.FromJson for Conversation with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Conversation raise @json.JsonDecodeError {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected object for Conversation"))
  }
  let name = match json.get("name") {
    Some(Null) => None
    Some([name]) | Some(name) => {
      let name : String = @json.from_json(name, path=json_path.add_key("name"))
      Some(name)
    }
    None => None
  }
  let description = match json.get("description") {
    Some(Null) => None
    Some(description) =>
      Some(@json.from_json(description, path=json_path.add_key("description")))
    None => None
  }
  let id = match json.get("id") {
    Some(id) => @json.from_json(id, path=json_path.add_key("id"))
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("id"), "Missing field 'id'"),
      )
  }
  let system_prompt : String? = match json.get("system_prompt") {
    Some(Null) => None
    Some(system_prompt) =>
      Some(
        @json.from_json(system_prompt, path=json_path.add_key("system_prompt")),
      )
    None => None
  }
  let messages = match json.get("messages") {
    Some(json) => {
      let messages : Array[Message] = @json.from_json(
        json,
        path=json_path.add_key("messages"),
      )
      messages
    }
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("messages"), "Missing field 'messages'"),
      )
  }
  let created_at = match json.get("created_at") {
    Some(Number(created_at, repr=None)) => created_at.to_int64()
    Some(created_at) =>
      @json.from_json(created_at, path=json_path.add_key("created_at"))
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("created_at"), "Missing field 'created_at'"),
      )
  }
  let updated_at = match json.get("updated_at") {
    Some(Number(created_at, repr=None)) => created_at.to_int64()
    Some(updated_at) =>
      @json.from_json(updated_at, path=json_path.add_key("updated_at"))
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("updated_at"), "Missing field 'updated_at'"),
      )
  }
  let cwd = match json.get("cwd") {
    Some(cwd) => Some(@json.from_json(cwd, path=json_path.add_key("cwd")))
    None => None
  }
  Conversation::{
    name,
    description,
    id,
    system_prompt,
    messages,
    created_at,
    updated_at,
    cwd,
  }
}

///|
pub fn Conversation::add_message(
  self : Conversation,
  message : Message,
) -> Unit {
  self.messages.push(message)
  self.updated_at = message.timestamp
}

///|
pub fn Conversation::add_messages(
  self : Conversation,
  messages : ArrayView[Message],
) -> Unit {
  for message in messages {
    self.add_message(message)
  }
}

///|
pub fn Conversation::id(self : Conversation) -> String {
  self.id
}

///|
pub fn Conversation::messages(
  self : Conversation,
  include_system? : Bool = true,
) -> Array[@ai.Message] {
  let msgs = []
  if include_system && self.system_prompt is Some(system_prompt) {
    msgs.push(@ai.system_message(content=system_prompt))
  }
  for m in self.messages {
    msgs.push(m.message)
  }
  msgs
}

///|
pub fn Conversation::system_prompt(self : Conversation) -> String? {
  self.system_prompt
}

///|
pub fn Conversation::set_system_prompt(
  self : Conversation,
  prompt : String?,
) -> Unit {
  self.system_prompt = prompt
}

///|
pub fn Conversation::cwd(self : Conversation) -> StringView? {
  self.cwd
}

///|
pub fn Conversation::name(self : Conversation) -> String? {
  self.name
}

///|
pub fn Conversation::description(self : Conversation) -> String? {
  self.description
}

///|
pub fn Conversation::created_at(self : Conversation) -> Int64 {
  self.created_at
}
