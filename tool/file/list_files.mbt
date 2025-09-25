///|
pub let list_files : @tool.Tool[Manager] = @tool.tool(
  description="List files in a directory",
  name="list_files",
  parameters={
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "The path to list files from, relative to the current working directory",
      },
    },
    "required": ["path"],
  },
  (args, self) => {
    guard args is { "path": String(path), .. } else {
      return @tool.error("Error: 'path' parameter is required")
    }
    try {
      let path = if @path.is_absolute(path) {
        path.view()
      } else {
        @path.join(self.cwd, path)
      }
      @tool.ok(@fs.list_directory(path).map(entry => entry.name).to_json())
    } catch {
      error => @tool.error("Error listing files: \{error}", error~)
    }
  },
  render=result => {
    guard result.output is Array(files) else {
      return "Error: Unexpected output format"
    }
    if files.length() == 0 {
      return "No files found."
    }
    let output = ["Files:"]
    for file in files {
      guard file is String(name) else { continue }
      output.push("- \{name}")
    }
    output.join("\n")
  },
)
