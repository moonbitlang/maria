///|
struct Conversation {
  name : String
  description : String?
  id : Id
  messages : Array[Message]
  created_at : Int64
  mut updated_at : Int64
}

///|
pub fn Conversation::display(
  self : Conversation,
  show_messages? : Bool = false,
) -> Array[String] raise {
  let lines = []
  lines.push("Name: \{self.name}")
  if self.description is Some(description) {
    lines.push("Description: \{description}")
  }
  if show_messages {
    for i, message in self.messages {
      let message = message.message
      match message {
        Assistant(assistant) => {
          lines.push("\{i}. [assistant]")
          let parts = assistant.content
          for part in parts {
            match part {
              Text(text) =>
                text.text.split("\n").each(line => lines.push("  \{line}"))
            }
          }
        }
        User(user) => {
          lines.push("\{i}. [user]")
          let parts = user.content
          for part in parts {
            match part {
              Text(text) =>
                text.text.split("\n").each(line => lines.push("  \{line}"))
            }
          }
        }
        System(system) => {
          lines.push("\{i}. [system]")
          let parts = system.content
          for part in parts {
            match part {
              Text(text) =>
                text.text.split("\n").each(line => lines.push("  \{line}"))
            }
          }
        }
        Tool(tool) => {
          lines.push("\{i}. [tool]")
          let parts = tool.content
          for part in parts {
            match part {
              Text(text) =>
                text.text.split("\n").each(line => lines.push("  \{line}"))
            }
          }
        }
      }
    }
  } else {
    lines.push("Messages: \{self.messages.length()}")
  }
  lines.push("Created: \{@time.unix(self.created_at / 1000).to_string()}")
  lines.push("Updated: \{@time.unix(self.updated_at / 1000).to_string()}")
  lines
}

///|
pub impl ToJson for Conversation with to_json(self) {
  fn int64_to_json(value : Int64) -> Json {
    Json::number(value.to_double(), repr=value.to_string())
  }

  let object : Map[String, Json] = {
    "name": self.name.to_json(),
    "id": self.id.to_json(),
    "messages": self.messages.to_json(),
    "created_at": int64_to_json(self.created_at),
    "updated_at": int64_to_json(self.updated_at),
  }
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
    Some(Number(created_at, repr=None)) => created_at.to_int64()
    Some(created_at) =>
      @json.from_json(created_at, path=json_path.add_key("created_at"))
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("created_at"), "Missing field"),
      )
  }
  let updated_at = match json.get("updated_at") {
    Some(Number(created_at, repr=None)) => created_at.to_int64()
    Some(updated_at) =>
      @json.from_json(updated_at, path=json_path.add_key("updated_at"))
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("updated_at"), "Missing field"),
      )
  }
  Conversation::{ name, description, id, messages, created_at, updated_at }
}

///|
priv struct Message {
  /// The Unix timestamp (in seconds) of when the message was created.
  timestamp : Int64
  /// Usage statistics for the completion request.
  usage : @openai.CompletionUsage?
  message : @openai.ChatCompletionMessageParam
}

///|
impl ToJson for Message with to_json(self) {
  let object : Map[String, Json] = {
    "timestamp": self.timestamp.to_json(),
    "message": self.message.to_json(),
  }
  if self.usage is Some(usage) {
    object["usage"] = usage.to_json()
  }
  object.to_json()
}

///|
impl @json.FromJson for Message with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Message raise @json.JsonDecodeError {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected object for Message"))
  }
  let timestamp = match json.get("timestamp") {
    Some(Number(timestamp, repr=None)) => timestamp.to_int64()
    Some(Number(_, repr=Some(repr))) =>
      @strconv.parse_uint64(repr).reinterpret_as_int64() catch {
        error =>
          raise @json.JsonDecodeError(
            (json_path.add_key("timestamp"), "Invalid timestamp: \{error}"),
          )
      }
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path.add_key("timestamp"), "Invalid timestamp"),
      )
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("timestamp"), "Missing field"),
      )
  }
  let usage = match json.get("usage") {
    Some(Null) => None
    Some(usage) => Some(@json.from_json(usage, path=json_path.add_key("usage")))
    None => None
  }
  let message = match json.get("message") {
    Some(message) => @json.from_json(message, path=json_path.add_key("message"))
    None => {
      let content : String = match json.get("content") {
        Some(content) =>
          @json.from_json(content, path=json_path.add_key("content"))
        None =>
          raise @json.JsonDecodeError(
            (json_path.add_key("content"), "Missing field"),
          )
      }
      let content = @json.parse(content) catch {
        error =>
          raise @json.JsonDecodeError(
            (json_path.add_key("content"), "Invalid JSON content: \{error}"),
          )
      }
      @json.from_json(content)
    }
  }
  Message::{ timestamp, usage, message }
}

///|
pub fn Conversation::new(
  name~ : String,
  description? : String,
  id~ : Id,
) -> Conversation raise {
  let now_ms = @os.now_ms()
  Conversation::{
    name,
    description,
    id,
    messages: [],
    created_at: now_ms,
    updated_at: now_ms,
  }
}

///|
pub fn Conversation::add_message(
  self : Conversation,
  message : @openai.ChatCompletionMessageParam,
  usage? : @openai.CompletionUsage,
  created? : Int64,
) -> Unit raise {
  let timestamp = match created {
    None => @os.now_ms()
    Some(created) => created
  }
  let message = Message::{ timestamp, usage, message }
  self.messages.push(message)
  self.updated_at = @os.now_ms()
}

///|
pub(all) struct Id(String)

///|
pub fn Id::new(rand~ : @random.Rand) -> Id {
  Id(@uuid.v4(rand~).to_string())
}

///|
pub impl Show for Id with output(self : Id, logger : &Logger) -> Unit {
  logger.write_string(self.0)
}

///|
pub impl ToJson for Id with to_json(self : Id) -> Json {
  self.0.to_json()
}

///|
pub impl @json.FromJson for Id with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Id raise @json.JsonDecodeError {
  let id : String = @json.from_json(json, path=json_path)
  id
}

///|
pub fn Conversation::id(self : Conversation) -> Id {
  self.id
}

///|
pub fn Conversation::to_param(
  self : Conversation,
) -> Array[@openai.ChatCompletionMessageParam] {
  let messages = []
  for m in self.messages {
    messages.push(m.message)
  }
  messages
}
