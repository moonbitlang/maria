///|
/// File entry with metadata for enhanced list_files output
priv struct FileEntry {
  name : String
  kind : String // "file", "directory", "symlink", etc.
  size : Int? // Size in bytes for files, None for directories
  is_hidden : Bool
} derive(ToJson, FromJson)

///|
/// Enhanced list_files result with metadata
priv struct ListFilesResult {
  path : String
  entries : Array[FileEntry]
  total_count : Int
  file_count : Int
  directory_count : Int
} derive(ToJson, FromJson)

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
      let result = ListFilesResult::{
        path,
        entries: file_entries,
        total_count: file_entries.length(),
        file_count,
        directory_count,
      }
      @tool.ok(result.to_json())
    } catch {
      error => @tool.error("Error listing files: \{error}", error~)
    }
  },
  render=result => {
    let list_result : ListFilesResult = @json.from_json(result.output) catch {
      error => return "Error: Unexpected output format: \{error}"
    }
    if list_result.total_count == 0 {
      return "No files found."
    }
    let output = []
    output.push("Directory: \{list_result.path}")
    output.push(
      "Total: \{list_result.total_count} items (\{list_result.file_count} files, \{list_result.directory_count} directories)",
    )
    output.push("")
    for entry in list_result.entries {
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
    output.join("\n")
  },
)
