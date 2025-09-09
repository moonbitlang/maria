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
      let path = @encoding.encode(context.cwd + "/" + path, encoding=UTF8)
      let dir = @fs.opendir(path)
      defer dir.close()
      let entries = []
      for entry in dir.read_all(include_special=true, include_hidden=true) {
        let entry = path + "/" + entry
        let file = @fs.open(entry, mode=ReadOnly)
        defer file.close()
        let entry = match file.kind() {
          Directory => entry + "/"
          _ => entry
        }
        entries.push(@encoding.decode(entry, encoding=UTF8))
      }
      @tool.ok(entries.join("\n"))
    } catch {
      error => @tool.error("Error listing files: \{error}", error~)
    }
  },
)
