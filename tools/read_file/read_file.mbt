///|
async fn @file.Manager::execute_read_file_tool(
  self : @file.Manager,
  args : Json,
) -> @tool.Result noraise {
  // Parse required path parameter
  guard args is { "path": String(path), .. } else {
    return @tool.error("Error: 'path' parameter is required")
  }
  let start_line : Int? = match args {
    { "start_line": Number(n, ..), .. } => Some(n.to_int())
    _ => None
  }
  let end_line : Int? = match args {
    { "end_line": Number(n, ..), .. } => Some(n.to_int())
    _ => None
  }
  try {
    // Resolve file path
    let resolved_path = if @path.is_absolute(path) {
      path.view()
    } else {
      @path.join(self.cwd, path)
    }
    let resolved_path = @path.resolve(resolved_path)

    // Check if file exists
    if !@fs.exists(resolved_path) {
      return @tool.error("Error reading file: File not found: \{path}")
    }
    if @fs.kind(resolved_path) is Directory {
      let entries = @fs.list_directory(resolved_path).map(entry => match
        entry.kind {
        Directory => "\{entry.name}\{@path.sep}"
        Regular => entry.name
        _ => entry.name
      })
      let display = entries.join("\n")
      return @tool.ok("Directory: \{path}\nEntries:\n\{display}")
    }

    // Open and read the file
    let content = @fs.read_file(resolved_path)

    // Update access time
    let stat = @fs.stat(resolved_path)
    self.access[resolved_path] = stat.atime()

    // Process line range parameters
    let lines = content.split("\n").to_array()
    let start_line = match start_line {
      Some(n) if n >= 1 => n
      Some(n) => return @tool.error("Error: start_line must be >= 1, got \{n}")
      None => 1
    }
    let end_line = match end_line {
      Some(end_line) => {
        if end_line < 1 {
          return @tool.error("Error: end_line must be >= 1, got \{end_line}")
        }
        if end_line <= start_line {
          return @tool.error(
            "Error: end_line (\{end_line}) must be greater than start_line (\{start_line})",
          )
        }
        if end_line > lines.length() {
          lines.length()
        } else {
          end_line
        }
      }
      None => lines.length()
    }
    let selected_lines = lines[start_line - 1:end_line]
    let selected_content = selected_lines.join("\n")
    let range_info = "lines \{start_line}-\{end_line} (\{selected_lines.length()} lines)"
    return @tool.ok("File: \{path} (\{range_info})\n\{selected_content}")
  } catch {
    error => @tool.error("Error reading file: \{error}")
  }
}

///|
pub let read_file : @tool.Tool[@file.Manager] = @tool.tool(
  description="Read the contents of a file at the specified path. Use this when you need to examine the contents of an existing file, for example to analyze code, review text files, or extract information from configuration files. For very large files (>30k tokens), the tool will automatically extract relevant sections based on the provided query to manage token usage efficiently. Supports reading specific line ranges with [start_line, end_line) format (1-indexed, end_line exclusive).",
  name="read_file",
  parameters={
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "The path of the file to read, relative to the current working directory",
      },
      "start_line": {
        "type": "number",
        "description": "Optional starting line number (1-indexed, inclusive). When specified with end_line, only reads the specified line range.",
      },
      "end_line": {
        "type": "number",
        "description": "Optional ending line number (1-indexed, exclusive). When specified with start_line, only reads the specified line range.",
      },
    },
    "required": ["path"],
  },
  (args, self) => self.execute_read_file_tool(args),
)
