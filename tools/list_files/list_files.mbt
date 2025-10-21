///|
/// File entry with metadata for enhanced list_files output
priv struct FileEntry {
  name : String
  kind : String // "file", "directory", "symlink", etc.
  size : Int? // Size in bytes for files, None for directories
  is_hidden : Bool
}

///|
pub let list_files : @tool.Tool[@file.Manager] = @tool.tool(
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
      let resolved_path = if @path.is_absolute(path) {
        path.view()
      } else {
        @path.join(self.cwd, path)
      }
      let entries = @fs.list_directory(resolved_path)
      let file_entries = []
      let mut file_count = 0
      let mut directory_count = 0
      for entry in entries {
        let kind_str = match entry.kind {
          Regular => {
            file_count = file_count + 1
            "file"
          }
          Directory => {
            directory_count = directory_count + 1
            "directory"
          }
          SymLink => "symlink"
          _ => "other"
        }

        // Check if file is hidden (starts with .)
        let is_hidden = entry.name.has_prefix(".")

        // File size is not available in the current fs API
        let size = None
        let file_entry = FileEntry::{
          name: entry.name,
          kind: kind_str,
          size,
          is_hidden,
        }
        file_entries.push(file_entry)
      }
      if file_entries.is_empty() {
        return @tool.ok("No files found.")
      } else {
        let output = []
        output.push("Directory: \{path}")
        output.push(
          "Total: \{file_entries.length()} items (\{file_count} files, \{directory_count} directories)",
        )
        output.push("")
        for entry in file_entries {
          let prefix = match entry.kind {
            "directory" => "📁"
            "file" => "📄"
            "symlink" => "🔗"
            _ => "❓"
          }
          let size_info = match entry.size {
            Some(size) => " (\{size} bytes)"
            None => ""
          }
          let hidden_marker = if entry.is_hidden { " [hidden]" } else { "" }
          output.push("\{prefix} \{entry.name}\{size_info}\{hidden_marker}")
        }
        @tool.ok(output.join("\n"))
      }
    } catch {
      error => @tool.error("Error listing files: \{error}", error~)
    }
  },
)
