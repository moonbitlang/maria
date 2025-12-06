///|
pub impl ToJson for Conversation with to_json(self : Conversation) -> Json {
  let object : Map[String, Json] = { "name": self.name, "id": self.id }
  if self.system_prompt is Some(system_prompt) {
    object["system_prompt"] = system_prompt.to_json()
  }
  object["messages"] = self.messages.to_json()
  object["created_at"] = self.created_at.to_json()
  object["updated_at"] = self.updated_at.to_json()
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
    Some(name) => {
      let name : String = @json.from_json(name, path=json_path.add_key("name"))
      name
    }
    None =>
      raise @json.JsonDecodeError((json_path.add_key("name"), "Missing field"))
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
      raise @json.JsonDecodeError((json_path.add_key("id"), "Missing field"))
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
        (json_path.add_key("messages"), "Missing field"),
      )
  }
  let created_at = match json.get("created_at") {
    Some(created_at) =>
      @json.from_json(created_at, path=json_path.add_key("created_at"))
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("created_at"), "Missing field"),
      )
  }
  let updated_at = match json.get("updated_at") {
    Some(updated_at) =>
      @json.from_json(updated_at, path=json_path.add_key("updated_at"))
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("updated_at"), "Missing field"),
      )
  }
  Conversation::{
    clock: @clock.epoch,
    name,
    description,
    id,
    system_prompt,
    messages,
    created_at,
    updated_at,
  }
}

///|
pub fn Conversation::display(
  self : Conversation,
  show_messages? : Bool = false,
) -> Array[String] {
  let lines = []
  lines.push("Name: \{self.name}")
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
