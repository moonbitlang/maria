///|
struct Counter {
  logger : @pino.Logger
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
pub fn Counter::new(logger~ : @pino.Logger) -> Counter raise {
  {
    logger,
    overhead: SystemOverhead,
    // tools: false, 
    encoding: @tiktoken.cl100k_base(),
  }
}

///|
fn Counter::_count_string(self : Counter, text : String) -> Int {
  self.encoding.encode(text).length()
}

///|
pub fn Counter::count_string(self : Counter, text : String) -> Int {
  self.overhead + self._count_string(text)
}

///|
fn Counter::count_tool_call(self : Counter, function : @ai.ToolCall) -> Int {
  self._count_string(function.id) +
  self._count_string(function.name) +
  (match function.arguments {
    Some(arguments) => self._count_string(arguments)
    None => 0
  })
}

///|
fn Counter::count_message(self : Counter, message : @ai.Message) -> Int {
  match message {
    Assistant(content, tool_calls~) => {
      let mut count = 0
      count += self.count_string(content)
      for tool_call in tool_calls {
        count += self._count_string(tool_call.id)
        count += self.count_tool_call(tool_call)
      }
      count
    }
    User(content) => self.count_string(content)
    System(content) => self.count_string(content)
    Tool(content, ..) => self.count_string(content)
  }
}

///|
fn Counter::count_messages(
  self : Counter,
  messages : Array[@ai.Message],
) -> Int {
  let mut count = 0
  for message in messages {
    count += self.count_message(message)
  }
  count
}

///|
fn Counter::count_tool(self : Counter, tool : @tool.ToolDesc) -> Int {
  let mut count = 0
  count += ToolOverhead
  count += self._count_string(tool.name)
  count += 2 * self._count_string(tool.description)
  let parameters = tool.schema.to_json().stringify(indent=2)
  let parameters = self._count_string(parameters)
  count += (parameters.to_double() / 2.0.sqrt()).to_int()
  count
}

///|
#cfg(false)
fn Counter::add_tool(
  self : Counter,
  tool : @ai.ChatCompletionToolParam,
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
pub async fn Counter::count_param(
  self : Counter,
  messages~ : Array[@ai.Message],
  tools? : Array[@tool.ToolDesc] = [],
) -> Int {
  let mut count = SystemOverhead
  if !tools.is_empty() {
    count += ToolsOverhead
  }
  for tool in tools {
    count += self.count_tool(tool)
  }
  count += self.count_messages(messages)
  self.logger.info("TokenCounted", data={ "token_count": count })
  count
}
