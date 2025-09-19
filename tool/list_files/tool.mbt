///|
pub let list_files : @tool.Tool = @tool.tool(
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
  (args, context) => {
    guard args is { "path": String(path), .. } else {
      return @tool.error("Error: 'path' parameter is required")
    }
    try {
      let path = if @path.is_absolute(path) {
        path.view()
      } else {
        @path.join(context.cwd, path)
      }
      let entries = @fs.list_directory(path).map(entry => entry.path)
      @tool.ok(entries.join("\n"))
    } catch {
      error => @tool.error("Error listing files: \{error}", error~)
    }
  },
)
