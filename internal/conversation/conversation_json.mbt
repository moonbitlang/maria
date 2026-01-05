///|
pub impl ToJson for Conversation with to_json(self : Conversation) -> Json {
  let object : Map[String, Json] = { "name": self.name, "id": self.id }
  object["events"] = self.events.to_json()
  object["created_at"] = self.created_at.to_json()
  object["updated_at"] = self.updated_at.to_json()
  if self.description is Some(description) {
    object["description"] = description.to_json()
  }
  object["cwd"] = self.cwd.to_json()
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
  let events = match json.get("events") {
    Some(json) => {
      let events : Array[@event.Event] = @json.from_json(
        json,
        path=json_path.add_key("events"),
      )
      events
    }
    None => {
      guard json.get("messages") is Some(messages) else {
        raise @json.JsonDecodeError(
          (json_path.add_key("events"), "Missing field"),
        )
      }
      let messages : Array[Message] = @json.from_json(
        messages,
        path=json_path.add_key("messages"),
      )
      let events = []
      let pending_tool_calls : Map[String, @ai.ToolCall] = Map::new()
      for message in messages {
        let id = @uuid.nil
        match message.message {
          Assistant(content, tool_calls~) => {
            for tc in tool_calls {
              pending_tool_calls[tc.id] = tc
            }
            let event = @event.Event::new(
              id~,
              @event.EventDesc::AssistantMessage(
                usage=message.usage,
                content,
                tool_calls~,
              ),
            )
            events.push(event)
          }
          User(content) => {
            let event = @event.Event::new(
              id~,
              @event.EventDesc::UserMessage(content),
            )
            events.push(event)
          }
          System(content) => {
            /// Semantically, a system message does not directly correspond to a
            /// SystemPromptSet event, but because we always store 0 or 1 system
            /// message in the past implementation, they are practically
            /// equivalent.
            let event = @event.Event::new(
              id~,
              @event.EventDesc::SystemPromptSet(Some(content)),
            )
            events.push(event)
          }
          Tool(content, tool_call_id~) =>
            match pending_tool_calls.get(tool_call_id) {
              Some(tc) => {
                pending_tool_calls.remove(tool_call_id)
                let event = @event.Event::new(
                  id~,
                  @event.EventDesc::PostToolCall(
                    tc,
                    result=Ok(content.to_json()),
                    rendered=content,
                  ),
                )
                events.push(event)
              }
              None =>
                raise @json.JsonDecodeError(
                  (
                    json_path,
                    "Tool message references unknown tool_call_id: \{tool_call_id}",
                  ),
                )
            }
        }
      }
      events
    }
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
  let cwd = match json.get("cwd") {
    Some(cwd) => @json.from_json(cwd, path=json_path.add_key("cwd"))
    None =>
      raise @json.JsonDecodeError((json_path.add_key("cwd"), "Missing field"))
  }
  Conversation::{
    clock: @clock.epoch,
    name,
    description,
    id,
    created_at,
    updated_at,
    cwd,
    events,
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
  let messages = self.messages(include_system=true)
  if show_messages {
    for i, message in messages {
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
    lines.push("Messages: \{messages.length()}")
  }
  fn show_time(ts : @clock.Timestamp) -> String {
    try @time.unix(ts.truncate_to_s()) catch {
      _ => return "invalid time".to_string()
    } noraise {
      t => t.to_string()
    }
  }

  lines.push("Created: \{show_time(self.created_at)}")
  lines.push("Updated: \{show_time(self.updated_at)}")
  lines
}
