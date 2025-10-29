///|
priv struct Formatter {
  path : String
  id : String?
  mut count : Int
  lines : Array[String]
  // Tool-specific logs are formatted using sub-formatters.
  tools : Map[String, Formatter]
}

///|
fn Formatter::new(path : String) -> Formatter {
  Formatter::{ path, id: None, count: 1, lines: [], tools: {} }
}

///|
fn Formatter::to_string(self : Formatter) -> String raise {
  let string = self.lines.join("\n")
  if self.id is Some(_) {
    return recover_diagnostics(string)
  } else {
    return string
  }
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
/// Number of context lines to show for recovered diagnostics. 1 means 1 line
/// before and 1 line after.
const ContextLines = 1

///|
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
      self.format_message_added(message)
    }
    _ => ()
  }
}
