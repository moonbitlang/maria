///|
/// Result of a successful match operation, containing position and length information
priv struct MatchResult {
  /// The starting position of the match in the original content
  position : Int
  /// The length of the matched content
  length : Int
} derive(ToJson)

///|
priv enum WriteResultOperation {
  Created
  Updated
  Replaced
}

///|
impl ToJson for WriteResultOperation with to_json(self : WriteResultOperation) -> Json {
  match self {
    Created => "created"
    Updated => "updated"
    Replaced => "replaced"
  }
}

///|
impl @json.FromJson for WriteResultOperation with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> WriteResultOperation raise {
  guard json is String(op) else {
    raise @json.JsonDecodeError(
      (json_path, "Invalid WriteResultOperation value: expected string"),
    )
  }
  match op {
    "created" => Created
    "updated" => Updated
    "replaced" => Replaced
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Invalid WriteResultOperation value: \{op}"),
      )
  }
}

///|
/// Write operation result for structured JSON output
priv struct WriteResult {
  path : String
  operation : WriteResultOperation
  bytes_written : Int
  search_used : Bool
  message : String
  content : String
} derive(ToJson, FromJson)

///|
/// Find a match in the haystack string using various matching strategies
///
/// Implements three matching strategies in order:
/// 1. Direct match: Exact string comparison
/// 2. Line-by-line: Compare each line ignoring leading/trailing whitespace
/// 3. First/last line match: For blocks ≥3 lines, match first and last lines
///
/// @param haystack The string to search in
/// @param needle The string to search for
/// @param fuzzy_match Whether to use fuzzy matching strategies (default: true)
/// @return Match result containing position and length, or None if no match found
fn find_match(
  haystack : String,
  needle : String,
  fuzzy_match? : Bool = true,
) -> MatchResult? {
  // Strategy 1: Direct match
  match haystack.find(needle) {
    None =>
      // Continue to fuzzy matching if enabled
      if !fuzzy_match {
        return None
      }
    Some(exact_match) =>
      return Some(MatchResult::{
        position: exact_match,
        length: needle.length(),
      })
  }

  // Prepare for line-based fuzzy matches
  let haystack_lines = haystack.split("\n").to_array()
  let needle_lines = needle.split("\n").to_array()
  let trimmed_haystack_lines = haystack_lines.map(fn(line) {
    line.trim(char_set=" \t\r\n").to_string()
  })
  let trimmed_needle_lines = needle_lines.map(fn(line) {
    line.trim(char_set=" \t\r\n").to_string()
  })

  /// Create a match result starting from a specific line index
  /// Calculates the exact position and length of the match in the original content
  ///
  /// @param start Starting line index in the haystack
  /// @return Match result with position and length
  fn fuzzy_match_from_line(start : Int) -> MatchResult {
    let matched_lines = []
    for i = start; i < start + needle_lines.length(); i = i + 1 {
      matched_lines.push(haystack_lines[i])
    }
    let matched_content = matched_lines.join("\n")
    let position = if start > 0 {
      let before_lines = []
      for i = 0; i < start; i = i + 1 {
        before_lines.push(haystack_lines[i])
      }
      before_lines.join("\n").length() + 1 // +1 for newline
    } else {
      0
    }
    MatchResult::{ position, length: matched_content.length() }
  }

  // Strategy 2: Line-by-line comparison ignoring whitespace
  for i = 0; i <= haystack_lines.length() - needle_lines.length(); i = i + 1 {
    let mut line_matches = true
    for j = 0; j < needle_lines.length(); j = j + 1 {
      if trimmed_haystack_lines[i + j] != trimmed_needle_lines[j] {
        line_matches = false
        break
      }
    }
    if line_matches {
      return Some(fuzzy_match_from_line(i))
    }
  }
  None
}

///|
test "find_match exact match" {
  let haystack = "Hello world\nThis is a test\nEnd of file"
  let needle = "This is a test"
  @json.inspect(find_match(haystack, needle), content=[
    { "position": 12, "length": 14 },
  ])
}

///|
test "find_match line-by-line with whitespace" {
  let haystack = "  line 1  \n  line 2  \n  line 3  "
  let needle = "line 1\nline 2"
  @json.inspect(find_match(haystack, needle), content=[
    { "position": 0, "length": 21 },
  ])
}

///|
test "find_match no match found" {
  let haystack = "Hello world"
  let needle = "Not found"
  @json.inspect(find_match(haystack, needle), content=null)
}

///|
test "find_match with fuzzy disabled works for exact substring" {
  let haystack = "  Hello world  "
  let needle = "Hello world"
  @json.inspect(find_match(haystack, needle, fuzzy_match=false), content=[
    { "position": 2, "length": 11 },
  ])
}

///|
/// Main execution function for the write_to_file tool
async fn @file.Manager::execute_write_to_file(
  self : @file.Manager,
  args : Json,
) -> @tool.Result noraise {
  // Parse required path parameter
  guard args is { "path": String(path), .. } else {
    return @tool.error("Error: 'path' parameter is required")
  }

  // Parse optional parameters with defaults
  let replace : String = match args {
    { "replace": String(r), .. } => r
    _ => ""
  }
  let search : String? = match args {
    { "search": String(s), .. } => Some(s)
    _ => None
  }
  try {
    // Resolve file path relative to current working directory
    let resolved_path = if @path.is_absolute(path) {
      path
    } else {
      @path.join(self.cwd, path)
    }
    let resolved_path = @path.resolve(resolved_path)

    // Check if file exists
    guard @fs.exists(resolved_path) else {
      // Create directory if it doesn't exist
      @fs.make_directory(@path.dirname(resolved_path), recursive=true)

      // File doesn't exist, create new file with replace content
      @fs.write_to_file(resolved_path, replace)
      let result = WriteResult::{
        path,
        operation: Created,
        bytes_written: replace.length(),
        search_used: false,
        message: "New file created and content written to \{path}",
        content: replace,
      }
      @tool.ok(result.to_json())
    }

    // Read existing file content
    let content = match search {
      None => {
        // Ensure the file has been read before writing
        guard self.access.get(resolved_path) is Some(access) else {
          return @tool.error(
            "Error: File must be read before writing to ensure consistency",
          )
        }

        // Check if file has been modified since last read
        let stat = @fs.stat(resolved_path)
        if stat.mtime() > access {
          return @tool.error(
            "Error: File has been modified since last read, please read it again before writing",
          )
        }

        // No search provided, replace entire file content
        replace
      }
      Some(search_content) => {
        let content = @fs.read_file(resolved_path)
        // Search and replace operation
        match find_match(content, search_content) {
          None =>
            return @tool.error(
              "Search content not found in file (tried all matching strategies): \{search_content}",
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
    @fs.write_to_file(resolved_path, content)
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
    @tool.ok(result.to_json())
  } catch {
    error => @tool.error("Error writing to file: \{error}", error~)
  }
}

///|
pub let write_to_file : @tool.Tool[@file.Manager] = @tool.tool(
  description="Write content to a file at the specified path using search/replace operation. For new files, provide only a replace parameter. For existing files, the search content must match exactly. This tool will automatically create any directories needed to write the file.",
  name="write_to_file",
  parameters={
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "The path of the file to write to, relative to the current working directory.",
      },
      "replace": {
        "type": "string",
        "description": "The content to replace with. If search is not provided, this will be the entire file content. If replace is not provided, the matched content will be deleted.",
      },
      "search": {
        "type": "string",
        "description": "The content to search for. If not provided, the entire file will be replaced with the replace content.",
      },
    },
    "required": ["path"],
  },
  (args, self) => self.execute_write_to_file(args),
  render=result => {
    let write_result : WriteResult = @json.from_json(result.output) catch {
      error => return "Error: Unexpected output format: \{error}"
    }
    write_result.message
  },
)
