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
      let cwd = @utf8.encode(context.cwd)
      let path = @utf8.encode(path)
      let dirname = @path.join(cwd, path)
      let dir = @fs.opendir(dirname)
      defer dir.close()
      let entries = []
      for basename in dir.read_all() {
        let filename = @path.join(dirname, basename)
        let file = @fs.open(filename, mode=ReadOnly)
        defer file.close()
        let basename : Bytes = match file.kind() {
          Directory => [..basename, @path.sep]
          _ => basename
        }
        entries.push(@utf8.decode(@path.join(path, basename)))
      }
      entries.sort()
      @tool.ok(entries.join("\n"))
    } catch {
      error => @tool.error("Error listing files: \{error}", error~)
    }
  },
)
