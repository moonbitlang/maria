///|
struct Counter {
  overhead : Int
  // mut tools : Bool
  encoding : @tiktoken.Encoding
}

///|
const SystemOverhead : Int = 7

///|
const ToolsOverhead : Int = 320

///|
const ToolOverhead : Int = 20

///|
/// Creates a new token counter with the cl100k\_base encoding.
///
/// Returns a new `Counter` instance configured with the tiktoken cl100k\_base
/// encoding, which is commonly used for OpenAI's GPT models.
///
/// Throws an error if the cl100k\_base encoding cannot be initialized.
pub fn Counter::new() -> Counter raise {
  {
    overhead: SystemOverhead,
    // tools: false, 
    encoding: @tiktoken.cl100k_base(),
  }
}

///|
fn Counter::_count_string(self : Counter, text : String) -> Int raise {
  self.encoding.encode(text).length()
}

///|
pub fn Counter::count_string(self : Counter, text : String) -> Int raise {
  self.overhead + self._count_string(text)
}

///|
fn Counter::count_content_parts(
  self : Counter,
  parts : Array[@openai.ChatCompletionContentPartParam],
) -> Int raise {
  let mut count = 0
  for part in parts {
    match part {
      Text(text) => count += self._count_string(text.text)
    }
  }
  count
}

///|
fn Counter::count_function(
  self : Counter,
  function : @openai.ChatCompletionMessageToolCallFunction,
) -> Int raise {
  self._count_string(function.name) + self._count_string(function.arguments)
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
        count += self._count_string(tool_call.id)
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
fn Counter::count_messages(
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
test "messages" {
  let messages = [
    @openai.user_message(content="Hello"),
    @openai.assistant_message(content="Hi there!"),
  ]
  let counter = Counter::new()
  @json.inspect(counter.count_messages(messages), content=4)
}

///|
fn Counter::count_tool(
  self : Counter,
  tool : @openai.ChatCompletionToolParam,
) -> Int raise {
  let mut count = 0
  count += ToolOverhead
  guard tool is @openai.Function(function)
  count += self._count_string(function.name)
  count += 2 * self._count_string(function.description)
  let parameters = function.parameters.to_json().stringify(indent=2)
  let parameters = self._count_string(parameters)
  count += (parameters.to_double() / 2.0.sqrt()).to_int()
  count
}

///|
test "tool" {
  let tool = @openai.tool(
    name="list_files",
    description="List files in a directory",
    parameters={
      "type": "object",
      "properties": {
        "path": {
          "type": "string",
          "description": "The directory path to list files from",
        },
      },
      "required": ["path"],
    },
  )
  let counter = Counter::new()
  @json.inspect(counter.count_tool(tool), content=70)
}

///|
#cfg(false)
fn Counter::add_tool(
  self : Counter,
  tool : @openai.ChatCompletionToolParam,
) -> Unit raise {
  if !self.tools {
    self.overhead += ToolsOverhead
    self.tools = true
  }
  self.overhead += self.count_tool(tool)
}

///|
/// Counts the total number of tokens required for a complete chat completion
/// request.
///
/// Parameters:
///
/// * `self` : The token counter instance.
/// * `param` : The chat completion parameters containing messages, tools, and
///   other configuration.
///
/// Returns the total token count including system overhead, tools overhead,
/// individual tool costs, and message content.
///
/// Throws an error if token encoding fails for any text content in the
/// parameters.
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
  count += self.count_messages(param.messages)
  count
}
