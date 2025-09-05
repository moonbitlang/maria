///|
struct Counter {
  encoding : @tiktoken.Encoding
  mut has_tool : Bool
  mut count : Int
}

///|
const SystemOverhead : Int = 7

///|
const ToolsOverhead : Int = 320

///|
const ToolOverhead : Int = 20

///|
pub fn Counter::new() -> Counter raise {
  { encoding: @tiktoken.cl100k_base(), count: SystemOverhead, has_tool: false }
}

///|
fn Counter::add_string(self : Counter, text : String) -> Unit raise {
  self.count += self.count_string(text)
}

///|
fn Counter::count_string(self : Counter, text : String) -> Int raise {
  self.encoding.encode(text).length()
}

///|
fn Counter::add_content_parts(
  self : Counter,
  parts : Array[@openai.ChatCompletionContentPartParam],
) -> Unit raise {
  for part in parts {
    match part {
      Text(text) => self.add_string(text.text)
    }
  }
}

///|
fn Counter::add_function(
  self : Counter,
  function : @openai.Function,
) -> Unit raise {
  self.add_string(function.name)
  self.add_string(function.arguments)
}

///|
fn Counter::add_message(
  self : Counter,
  message : @openai.ChatCompletionMessageParam,
) -> Unit raise {
  match message {
    Assistant(assistant) => {
      self.add_content_parts(assistant.content)
      for tool_call in assistant.tool_calls {
        self.add_string(tool_call.id)
        self.add_function(tool_call.function)
      }
    }
    User(user) => self.add_content_parts(user.content)
    System(system) => self.add_content_parts(system.content)
    Tool(tool) => self.add_content_parts(tool.content)
  }
}

///|
pub fn Counter::add_messages(
  self : Counter,
  messages : Array[@openai.ChatCompletionMessageParam],
) -> Unit raise {
  for message in messages {
    self.add_message(message)
  }
}

///|
pub fn Counter::add_tool(
  self : Counter,
  tool_call : @openai.ChatCompletionToolParam,
) -> Unit raise {
  if !self.has_tool {
    self.has_tool = true
    self.count += ToolsOverhead
  }
  self.count += ToolOverhead
  guard tool_call is @openai.Function(function)
  self.add_string(function.name)
  self.count += 2 * self.count_string(function.description)
  let parameters = function.parameters.to_json().stringify(indent=2)
  let parameters = self.count_string(parameters)
  self.count += (parameters.to_double() / 2.0.sqrt()).to_int()
}

///|
pub fn Counter::count(self : Counter) -> Int {
  let count = self.count
  self.has_tool = false
  self.count = SystemOverhead
  return count
}
