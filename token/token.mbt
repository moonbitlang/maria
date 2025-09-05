///|
struct Counter {
  encoding : @tiktoken.Encoding
}

///|
const SystemOverhead : Int = 7

///|
const ToolsOverhead : Int = 320

///|
const ToolOverhead : Int = 20

///|
pub fn Counter::new() -> Counter raise {
  { encoding: @tiktoken.cl100k_base() }
}

///|
fn Counter::count_string(self : Counter, text : String) -> Int raise {
  self.encoding.encode(text).length()
}

///|
fn Counter::count_content_parts(
  self : Counter,
  parts : Array[@openai.ChatCompletionContentPartParam],
) -> Int raise {
  let mut count = 0
  for part in parts {
    match part {
      Text(text) => count += self.count_string(text.text)
    }
  }
  count
}

///|
fn Counter::count_function(
  self : Counter,
  function : @openai.Function,
) -> Int raise {
  self.count_string(function.name) + self.count_string(function.arguments)
}

///|
fn Counter::count_message(
  self : Counter,
  message : @openai.ChatCompletionMessageParam,
) -> Int raise {
  match message {
    Assistant(assistant) => {
      let mut count = 0
      count += self.count_content_parts(assistant.content)
      for tool_call in assistant.tool_calls {
        count += self.count_string(tool_call.id)
        count += self.count_function(tool_call.function)
      }
      count
    }
    User(user) => self.count_content_parts(user.content)
    System(system) => self.count_content_parts(system.content)
    Tool(tool) => self.count_content_parts(tool.content)
  }
}

///|
pub fn Counter::count_messages(
  self : Counter,
  messages : Array[@openai.ChatCompletionMessageParam],
) -> Int raise {
  let mut count = 0
  for message in messages {
    count += self.count_message(message)
  }
  count
}

///|
pub fn Counter::count_tool(
  self : Counter,
  tool : @openai.ChatCompletionToolParam,
) -> Int raise {
  let mut count = 0
  count += ToolOverhead
  guard tool is @openai.Function(function)
  count += self.count_string(function.name)
  count += 2 * self.count_string(function.description)
  let parameters = function.parameters.to_json().stringify(indent=2)
  let parameters = self.count_string(parameters)
  count += (parameters.to_double() / 2.0.sqrt()).to_int()
  count
}

///|
pub fn Counter::count_param(
  self : Counter,
  param : @openai.ChatCompletionParam,
) -> Int raise {
  let mut count = SystemOverhead
  if !param.tools.is_empty() {
    count += ToolsOverhead
  }
  for tool in param.tools {
    count += self.count_tool(tool)
  }
  for message in param.messages {
    count += self.count_message(message)
  }
  count
}
