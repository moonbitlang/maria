///|
fn json2xml(json : Json, indent? : Int = 0, output : Array[String]) -> Unit {
  match json {
    Object(object) =>
      for key, value in object {
        output.push(" ".repeat(indent) + "<\{key}>")
        json2xml(value, indent=indent + 2, output)
        output.push(" ".repeat(indent) + "</\{key}>")
      }
    Array(array) =>
      // TODO: it might be not correct to just output array items directly, but
      // for now this is much more readable than:
      //
      // ```xml
      // <item>
      //   ...
      // </item>
      // <item>
      //   ...
      // </item>
      // ...
      // ```
      //
      // so we keep it as is.
      for item in array {
        json2xml(item, indent~, output)
      }
    String(string) =>
      for line in string.split("\n") {
        if line.is_empty() {
          output.push("")
        } else {
          output.push([.." ".repeat(indent), ..line])
        }
      }
    Number(_, repr=Some(repr)) => output.push(" ".repeat(indent) + repr)
    Number(value, repr=None) =>
      output.push(" ".repeat(indent) + value.to_string())
    True => output.push(" ".repeat(indent) + "true")
    False => output.push(" ".repeat(indent) + "false")
    Null => output.push(" ".repeat(indent) + "null")
  }
}

///|
test "json2xml" {
  let lines = []
  json2xml({ "greeting": "hello", "items": [1, 2, 3], "active": true }, lines)
  inspect(
    lines.join("\n"),
    content=(
      #|<greeting>
      #|  hello
      #|</greeting>
      #|<items>
      #|  1
      #|  2
      #|  3
      #|</items>
      #|<active>
      #|  true
      #|</active>
    ),
  )
  lines.clear()
  json2xml([1, "A", true, null], lines)
  inspect(
    lines.join("\n"),
    content=(
      #|1
      #|A
      #|true
      #|null
    ),
  )
}

///|
priv struct Formatter {
  path : String
  id : String?
  mut count : Int
  lines : Array[String]
  tools : Map[String, Formatter]
}

///|
fn Formatter::new(path : String) -> Formatter {
  Formatter::{ path, id: None, count: 1, lines: [], tools: {} }
}

///|
fn Formatter::to_string(self : Formatter) -> String {
  self.lines.join("\n")
}

///|
async fn Formatter::format_tool_call(
  self : Formatter,
  tool_call : @openai.ChatCompletionMessageToolCall,
) -> Unit {
  self.lines.push("## Tool call argument: <\{tool_call.function.name}>")
  self.lines.push("")
  try {
    let args = @json.parse(tool_call.function.arguments)
    if tool_call.function.name is ("replace_in_file" | "meta_write_to_file") {
      match args {
        {
          "path": String(path),
          "search": String(search),
          "replace": String(replace),
          ..
        } => {
          self.lines.push("Replacing in file \{path}")
          self.lines.push("")
          self.lines.push("```diff")
          self.lines.push(
            @git.generate_git_diff(original=search, modified=replace),
          )
          self.lines.push("```")
        }
        { "path": String(path), "replace": String(replace), .. } => {
          let file_format = if path.has_suffix(".mbt") {
            Some("moonbit")
          } else if path.has_suffix(".json") {
            Some("json")
          } else if path.has_suffix(".md") {
            Some("markdown")
          } else {
            None
          }
          if file_format is Some(file_format) {
            self.lines.push("Writing to file \{path}")
            self.lines.push("")
            if file_format is "markdown" {
              self.lines.push("````\{file_format}")
            } else {
              self.lines.push("```\{file_format}")
            }
            self.lines.push(replace)
            if file_format is "markdown" {
              self.lines.push("````")
            } else {
              self.lines.push("```")
            }
          } else {
            json2xml(args, self.lines)
          }
        }
        _ => json2xml(args, self.lines)
      }
    } else if tool_call.function.name is "submit_fixed_file" &&
      args is { "content": String(content), .. } {
      self.lines.push("Submitting fixed file content:")
      self.lines.push("")
      self.lines.push("```moonbit")
      self.lines.push(content)
      self.lines.push("```")
    } else {
      json2xml(args, self.lines)
    }
    self.lines.push("")
  } catch {
    _ => self.lines.push(tool_call.function.arguments)
  }
}

///|
async fn Formatter::format_log_entry(self : Formatter, json : Json) -> Unit {
  if self.id is None &&
    json is { "tool": { "name": String(name), "id": String(id), .. }, .. } {
    match self.tools.get(id) {
      Some(formatter) => {
        formatter.format_log_entry(json)
        return
      }
      None => {
        let path = "\{self.path}-\{id}.md"
        let formatter = Formatter::{
          path,
          id: Some(id),
          count: 1,
          lines: [],
          tools: {},
        }
        self.tools.set(id, formatter)
        self.lines.push("## Spawned subagent for tool: <\{name}>")
        self.lines.push("")
        self.lines.push("[<\{name}> log](\{path})")
        self.lines.push("")
        formatter.format_log_entry(json)
        return
      }
    }
  }
  match json {
    { "msg": "RequestCompleted", "message": message, .. } => {
      let message : @openai.ChatCompletionMessage = @json.from_json(message)
      let content = message.content
        .unwrap_or("")
        .trim(char_set=" \n\r\t")
        .to_string()
      let title = content.split("\n").drop_while(line => line.is_blank()).peek()
      if title is Some(title) {
        self.lines.push("# \{self.count} Assistant: \{title}")
        self.count += 1
        self.lines.push("")
        self.lines.push(content)
        self.lines.push("")
      } else {
        self.lines.push("# \{self.count} Assistant")
        self.count += 1
        if !content.is_empty() {
          self.lines.push(content)
        }
        self.lines.push("")
      }
      if message.tool_calls.length() > 0 {
        for tool_call in message.tool_calls {
          self.format_tool_call(tool_call)
        }
      }
    }
    { "msg": "PostToolCall", "name": String(name), "text": String(text), .. } => {
      self.lines.push("# \{self.count} Tool call result: <\{name}>")
      self.count += 1
      self.lines.push("")
      self.lines.push("````markdown")
      self.lines.push(text)
      self.lines.push("````")
      self.lines.push("")
    }
    { "msg": "MessageAdded", "message": message, .. } => {
      let message : @openai.ChatCompletionMessageParam = @json.from_json(
        message,
      )
      if message is (Tool(_) | System(_)) {
        return
      }
      let role = openai_message_role(message)
      let content = openai_message_content(message)
        .trim(char_set=" \n\r\t")
        .to_string()
      let title = content.split("\n").drop_while(line => line.is_blank()).peek()
      if title is Some(title) {
        self.lines.push("# \{self.count} \{role}: \{title}")
        self.count += 1
        self.lines.push("")
        self.lines.push(content)
        self.lines.push("")
      } else {
        self.lines.push("# \{self.count} \{role}")
        self.count += 1
        if !content.is_empty() {
          self.lines.push(content)
        }
        self.lines.push("")
      }
    }
    _ => ()
  }
}

///|
async test "format_log_entry/MessageAdded" {
  let formatter = Formatter::new("test.md")
  let log_entry : Json = {
    "msg": "MessageAdded",
    "message": {
      "role": "user",
      "content": [{ "type": "text", "text": "Hello, how are you?" }],
    },
  }
  formatter.format_log_entry(log_entry)
  inspect(
    formatter.to_string(),
    content=(
      #|# 1 User: Hello, how are you?
      #|
      #|Hello, how are you?
      #|
    ),
  )
}

///|
async test "format_log_entry/RequestCompleted" {
  let formatter = Formatter::new("test.md")
  let log_entry : Json = {
    "msg": "RequestCompleted",
    "message": {
      "role": "assistant",
      "content": "I am fine, thank you!",
      "tool_calls": [
        {
          "id": "tool_call_1",
          "function": {
            "name": "get_weather",
            "arguments": "{\"location\": \"New York\"}",
          },
        },
      ],
    },
  }
  formatter.format_log_entry(log_entry)
  inspect(
    formatter.to_string(),
    content=(
      #|# 1 Assistant: I am fine, thank you!
      #|
      #|I am fine, thank you!
      #|
      #|## Tool call argument: <get_weather>
      #|
      #|<location>
      #|  New York
      #|</location>
      #|
    ),
  )
}

///|
async test "format_log_entry/PostToolCall" {
  let formatter = Formatter::new("test.md")
  let log_entry : Json = {
    "msg": "PostToolCall",
    "name": "get_weather",
    "text": "The weather in New York is sunny.",
  }
  formatter.format_log_entry(log_entry)
  inspect(
    formatter.to_string(),
    content=(
      #|# 1 Tool call result: <get_weather>
      #|
      #|````markdown
      #|The weather in New York is sunny.
      #|````
      #|
    ),
  )
}

///|
async test "format_log_entry/MessageAdded with multiline tool content" {
  let formatter = Formatter::new("test.md")
  let log_entry : Json = {
    "msg": "MessageAdded",
    "message": {
      "role": "tool",
      "tool_call_id": "call_123",
      "content": [
        {
          "type": "text",
          "text": "✅ Operation completed: Marked task as completed\n\n📝 Current todo list:\n  🟡 ✅ [ea45749e] Create project structure\n  🟡 ⏳ [1efbf50f] Define data structures\n\n📊 Summary: Total 2 items",
        },
      ],
    },
  }
  formatter.format_log_entry(log_entry)
  // The tool message should be ignored and produce no output, as the result
  // is already logged in PostToolCall.
  inspect(formatter.to_string(), content="")
  let log_entry : Json = {
    "msg": "MessageAdded",
    "message": {
      "role": "system",
      "content": [
        { "type": "text", "text": "System maintenance scheduled at midnight." },
      ],
    },
  }
  formatter.format_log_entry(log_entry)
  // The system message should be ignored and produce no output.
  inspect(formatter.to_string(), content="")
}

///|
async fn main {
  let args = @os.args()
  @backtrace.initialize()
  guard args is [_, .. args] else {
    println("Usage: jsonl2md <log-file> --output <markdown-file>")
    return
  }
  let mut input_path = None
  let mut output_path = None
  loop args {
    ["--output" | "-o", path, .. args] => {
      output_path = Some(path)
      continue args
    }
    [['-', ..] as option, ..] => {
      println("Error: Unknown argument: \{option}")
      return
    }
    [log_file, .. args] => {
      input_path = Some(log_file)
      continue args
    }
    [] => ()
  }
  guard input_path is Some(input_path) else {
    println("Error: <log-file> is required")
    return
  }
  let output_path = if output_path is Some(output_path) {
    output_path
  } else {
    @path.stem(input_path).to_string() + ".md"
  }
  let formatter = Formatter::new(output_path)
  let jsonl_text = @fs.read_file(input_path)
  for json_text in jsonl_text.split("\n").collect() {
    if json_text.trim_space().is_empty() {
      continue
    }
    let json = @json.parse(json_text) catch {
      error => {
        println("Warning: Failed to parse JSON line: \{error}\n\{json_text}")
        continue
      }
    }
    formatter.format_log_entry(json)
  }
  @fs.make_directory(@path.dirname(output_path))
  @fs.write_to_file(output_path, formatter.to_string())
  for tool_formatter in formatter.tools.values().collect() {
    @fs.write_to_file(tool_formatter.path, tool_formatter.to_string())
  }
}

///|
fn openai_message_role(message : @openai.ChatCompletionMessageParam) -> String {
  match message {
    User(_) => "User"
    Assistant(_) => "Assistant"
    System(_) => "System"
    Tool(_) => "Tool"
  }
}

///|
fn openai_message_content(
  message : @openai.ChatCompletionMessageParam,
) -> String {
  match message {
    User(user_message) => {
      let builder = StringBuilder::new()
      for part in user_message.content {
        if part is Text(text) {
          builder.write_string(text.text)
        }
      }
      builder.to_string()
    }
    Assistant(assistant_message) => {
      let builder = StringBuilder::new()
      for part in assistant_message.content {
        if part is Text(text) {
          builder.write_string(text.text)
        }
      }
      builder.to_string()
    }
    System(system_message) => {
      let builder = StringBuilder::new()
      for part in system_message.content {
        if part is Text(text) {
          builder.write_string(text.text)
        }
      }
      builder.to_string()
    }
    Tool(tool_message) => {
      let builder = StringBuilder::new()
      for part in tool_message.content {
        if part is Text(text) {
          builder.write_string(text.text)
        }
      }
      builder.to_string()
    }
  }
}
