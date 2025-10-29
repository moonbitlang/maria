///|
priv struct Formatter {
  recover_diagnostics : Bool
  /// Output markdown file path.
  path : String
  /// Tool ID if this is a sub-formatter.
  id : String?
  /// Number of messages in this log.
  mut count : Int
  /// Formatted lines.
  lines : Array[String]
  /// Tool-specific logs are formatted using sub-formatters.
  tools : Map[String, Formatter]
}

///|
fn Formatter::new(
  path : String,
  recover_diagnostics? : Bool = false,
) -> Formatter {
  Formatter::{
    recover_diagnostics,
    path,
    id: None,
    count: 1,
    lines: [],
    tools: {},
  }
}

///|
fn Formatter::to_string(self : Formatter) -> String raise {
  let string = self.lines.join("\n")
  // Recover diagnostics only if this is a sub-formatter
  if self.id is Some(_) && self.recover_diagnostics {
    return recover_diagnostics(string)
  } else {
    return string
  }
}

///|
fn Formatter::format_tool_call_as_xml(
  self : Formatter,
  name : String,
  args : Json,
) -> Unit {
  // Some heuristic formatting for common tool call arguments
  if args is { "path": String(path), .. } {
    self.lines.push("## Tool call argument: <\{name} path=\{path.escape()}>")
  } else if args is { "command": String(command), .. } {
    self.lines.push(
      "## Tool call argument: <\{name} command=\{command.escape()}>",
    )
  } else {
    self.lines.push("## Tool call argument: <\{name}>")
  }
  self.lines.push("")
  json2xml(args, self.lines)
}

///|
async fn Formatter::format_replace_in_file(
  self : Formatter,
  name : String,
  args : Json,
) -> Unit {
  match args {
    {
      "path": String(path),
      "search": String(search),
      "replace": String(replace),
      ..
    } => {
      self.lines.push("## Tool call argument: <\{name} path=\{path.escape()}>")
      self.lines.push("")
      self.lines.push("```diff")
      self.lines.push(@git.generate_git_diff(original=search, modified=replace))
      self.lines.push("```")
    }
    { "path": String(path), "replace": String(replace), .. } => {
      self.lines.push("## Tool call argument: <\{name} path=\{path.escape()}>")
      self.lines.push("")
      let file_format = if path.has_suffix(".mbt") {
        "moonbit"
      } else if path.has_suffix(".json") {
        "json"
      } else if path.has_suffix(".md") {
        "markdown"
      } else {
        "plaintext"
      }
      self.lines.push("")
      if file_format is "markdown" {
        self.lines.push("````\{file_format}")
        self.lines.push(replace)
        self.lines.push("````")
      } else {
        self.lines.push("```\{file_format}")
        self.lines.push(replace)
        self.lines.push("```")
      }
    }
    _ => self.format_tool_call_as_xml(name, args)
  }
}

///|
fn Formatter::format_submit_fixed_file(
  self : Formatter,
  name : String,
  args : Json,
) -> Unit {
  match args {
    { "content": String(content), .. } => {
      self.lines.push("## Tool call argument: <\{name}>")
      self.lines.push("")
      self.lines.push("Submitting fixed file content:")
      self.lines.push("")
      self.lines.push("```moonbit")
      self.lines.push(content)
      self.lines.push("```")
    }
    _ => self.format_tool_call_as_xml(name, args)
  }
}

///|
/// Formats tool call from a MessageAdded log entry.
async fn Formatter::format_tool_call(
  self : Formatter,
  tool_call : @openai.ChatCompletionMessageToolCall,
) -> Unit {
  try @json.parse(tool_call.function.arguments) catch {
    error => {
      self.lines.push("## Tool call argument: <\{tool_call.function.name}>")
      self.lines.push("")
      self.lines.push("Failed to parse tool call arguments as JSON: \{error}")
      self.lines.push("")
      self.lines.push("```json")
      self.lines.push(tool_call.function.arguments)
      self.lines.push("```")
    }
  } noraise {
    args =>
      if tool_call.function.name is ("replace_in_file" | "meta_write_to_file") {
        self.format_replace_in_file(tool_call.function.name, args)
      } else if tool_call.function.name is "submit_fixed_file" {
        self.format_submit_fixed_file(tool_call.function.name, args)
      } else {
        self.format_tool_call_as_xml(tool_call.function.name, args)
      }
  }
  self.lines.push("")
}

///|
/// Number of context lines to show for recovered diagnostics. 1 means 1 line
/// before and 1 line after.
const ContextLines = 1

///|
/// Recovers diagnostic context from file content embedded in the log.
fn recover_diagnostics(content : String) -> String raise {
  let lines = content.split("\n").collect()
  // 1. Collect source
  let source = StringBuilder::new()
  // Matches lines like this
  //
  // `````
  // # 3 Tool call result: <read_file>
  //
  // ````markdown
  // File content:
  // <moonbit-source>
  // `````
  loop lines[:] {
    [title, "", "````markdown", "File content:", .. rest] if title.has_suffix(
        "Tool call result: <read_file>",
      ) =>
      continue source~: loop rest {
          ["````", .. rest] => break rest
          [line, .. rest] => {
            source.write_string([..line, '\n'])
            continue source~ rest
          }
          [] => break []
        }
    [_, .. rest] => continue rest
    [] => break
  }
  let source_lines = source.to_string().split("\n").collect()
  // 2. Recover diagnostics
  let recovered = []
  loop lines[:] {
    [] => break
    [line, .. rest] => {
      recovered.push(line)
      // Matches
      // error[<code>]: <file>:<line>:<column>: ...
      lexmatch line with longest {
        (
          "error\["
          "\d{4}"
          "\]:\s+"
          "[^:]*"
          ":"
          ("\d+" as line)
          ":"
          ("\d+" as column)
          ":\s+",
          _
        ) => {
          let line = @strconv.parse_int(line) - 1
          let context_start = @cmp.maximum(0, line - ContextLines)
          let context_end = @cmp.minimum(
            source_lines.length() - 1,
            line + ContextLines,
          )
          let column = @strconv.parse_int(column)
          let line_number = (line + 1).to_string()
          let line_number_width = (line + 1).to_string().length()
          let indent = " ".repeat(line_number_width)
          for i in context_start..<line {
            recovered.push("\{indent} │\{source_lines[i]}")
          }
          recovered.push("\{line_number} │\{source_lines[line]}")
          let padding = " ".repeat(column - 1)
          recovered.push("\{indent} │\{padding}^")
          for i in (line + 1)..=context_end {
            recovered.push("\{indent} │\{source_lines[i]}")
          }
        }
        _ => ()
      }
      continue rest
    }
  }
  recovered.join("\n")
}

///|
/// Formats a MessageAdded log entry.
async fn Formatter::format_message_added(
  self : Formatter,
  message : @openai.ChatCompletionMessageParam,
) -> Unit {
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

///|
/// Formats a log entry from JSON.
async fn Formatter::format_log_entry(self : Formatter, json : Json) -> Unit {
  if self.id is None &&
    json is { "tool": { "name": String(name), "id": String(id), .. }, .. } {
    // If we found a log entry with "tool" field, delegate to sub-formatter,
    // create if there is no matching sub-formatter.
    match self.tools.get(id) {
      Some(formatter) => {
        formatter.format_log_entry(json)
        return
      }
      None => {
        // No sub-formatter found, create a new one and link to the sub-log file
        // in the main log.
        let path = "\{self.path}-\{id}.md"
        let formatter = Formatter::{
          recover_diagnostics: self.recover_diagnostics,
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
      self.format_message_added(message)
    }
    _ => ()
  }
}
