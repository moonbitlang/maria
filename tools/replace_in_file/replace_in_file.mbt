///|
using @path {type Path}

///|
priv enum WriteResultOperation {
  Created
  Updated
  Replaced
} derive(ToJson, FromJson)

///|
/// Write operation result for structured JSON output
struct WriteResult {
  path : String
  operation : WriteResultOperation
  bytes_written : Int
  search_used : Bool
  message : String
  content : String
} derive(ToJson, FromJson)

///|
pub impl Show for WriteResult with output(self : WriteResult, logger : &Logger) -> Unit {
  logger.write_string(self.message)
}

///|
impl @tool.ToolOutput for WriteResult with to_message(self) {
  @ai.tool_message(content=self.to_string(), tool_call_id="")
}

///|
/// Main execution function for the replace_in_file tool
async fn @file.Manager::execute_replace_in_file(
  self : @file.Manager,
  args : Json,
) -> @tool.ToolResult noraise {
  let { path, replace, search } : Input = @json.from_json(args) catch {
    error =>
      return @tool.failed(
        "Error: Invalid arguments provided to replace_in_file tool: \{error}",
      )
  }
  try {
    // Resolve file path relative to current working directory
    let resolved_path = if Path::is_absolute(path) {
      path
    } else {
      Path::join(self.cwd, path).to_string()
    }
    let resolved_path = Path::resolve(resolved_path).to_string()

    // Check if file exists
    guard @fsx.exists(resolved_path) else {
      // Create directory if it doesn't exist
      @fsx.make_directory(
        Path::dirname(resolved_path).to_string(),
        recursive=true,
        exists_ok=true,
      )

      // File doesn't exist, create new file with replace content
      @fsx.write_to_file(resolved_path, replace)
      let result = WriteResult::{
        path,
        operation: Created,
        bytes_written: replace.length(),
        search_used: false,
        message: "New file created and content written to \{path}",
        content: replace,
      }
      @tool.success(result)
    }

    // Read existing file content
    let content = match search {
      None | Some("") =>
        // No search provided, replace entire file content
        replace
      Some(search_content) => {
        let content = @fsx.read_file(resolved_path)
        // Search and replace operation
        match @fuzzy.find_match(content, search_content) {
          None =>
            return @tool.failed(
              (
                $|Search content not found in file (tried all matching strategies)
                $|
                $|```
                $|\{search_content}
                $|```
                $|
                $|File content:
                $|
                $|```
                $|\{content}
                $|```
              ),
            )
          Some(match_result) => {
            // Replace at the exact position to maintain formatting
            let before = content[0:match_result.position].to_string()
            let after = content[match_result.position + match_result.length:].to_string()
            before + replace + after
          }
        }
      }
    }

    // Write the modified content back to file
    @fsx.write_to_file(resolved_path, content)
    let operation = match search {
      None => Replaced
      Some(_) => Updated
    }
    let result = WriteResult::{
      path,
      operation,
      bytes_written: content.length(),
      search_used: search is Some(_),
      message: "Changes applied to \{path}",
      content,
    }
    @tool.success(result)
  } catch {
    @os_error.OSError(_, ..) as error if error.is_EACCES() =>
      @tool.failed(
        "Permission denied: Cannot write to file \{path}. The file does not have write permissions.",
      )
    error => @tool.failed("Error writing to file: \{error}")
  }
}

///|
pub fn new(manager : @file.Manager) -> @tool.Tool {
  @tool.new(
    description="Write content to a file at the specified path using search/replace operation. For new files, provide only a replace parameter. For existing files, the search content must match exactly. This tool will automatically create any directories needed to write the file.",
    name="replace_in_file",
    schema~,
    async fn(args) -> @tool.ToolResult noraise {
      manager.execute_replace_in_file(args)
    },
  )
}
