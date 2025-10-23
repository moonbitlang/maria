///|
/// Search result structure matching Python version
priv struct SearchResult {
  context : String
  line_number : Int
  match_line : String
  path : String
} derive(ToJson, FromJson)

///|
/// Error types for search operations
priv suberror SearchError {
  FileReadError(path~ : String, error~ : String)
  MoonAnalysisError(query~ : String, error~ : String)
} derive(ToJson, Show)

///|
/// Search kind enumeration
priv enum SearchKind {
  Regex
  MoonbitDefinition
  MoonbitReferences
} derive(ToJson, FromJson)

///|
/// Parse search kind from string
fn SearchKind::from_string(kind : String) -> SearchKind? {
  match kind {
    "regex" => Some(Regex)
    "moonbit_definition" => Some(MoonbitDefinition)
    "moonbit_references" => Some(MoonbitReferences)
    _ => None
  }
}

///|
/// Recursive directory traversal to collect files matching pattern
async fn collect_files_recursive(
  directory : String,
  file_pattern : String,
  base_dir : String,
) -> Array[String] {
  let results = []
  let entries = @fs.list_directory(directory)
  for entry in entries {
    let full_path = @path.join(directory, entry.name)
    match entry.kind {
      Directory => {
        // Recursively collect from subdirectories
        let sub_results = collect_files_recursive(
          full_path, file_pattern, base_dir,
        )
        results.append(sub_results)
      }
      Regular =>
        // Check if file matches pattern (simple glob-like matching)
        if matches_pattern(entry.name, file_pattern) {
          results.push(full_path)
        }
      _ => () // Skip other file types
    }
  }
  results
}

///|
/// Simple glob pattern matching (supports * wildcard)
fn matches_pattern(filename : String, pattern : String) -> Bool raise {
  if pattern == "*" {
    return true
  }

  // Handle simple *.ext patterns
  if pattern.has_prefix("*.") {
    let extension = pattern[2:].to_string()
    return filename.has_suffix(".\{extension}")
  }

  // Exact match for other patterns
  filename == pattern
}

///|
/// Perform regex search in file content
async fn search_in_file(
  file_path : String,
  regex : @regexp.Regexp,
  context_lines : Int,
  base_dir : String,
) -> Array[SearchResult] raise SearchError {
  let content = @fs.read_file(file_path) catch {
    error =>
      raise SearchError::FileReadError(path=file_path, error=error.to_string())
  }
  let lines = content.split("\n").collect() // Convert to Array
  let results = []
  let relative_path = @path.relative(base_dir, file_path) catch {
    _ => file_path // fallback to absolute path if relative fails
  }
  for i = 0; i < lines.length(); i = i + 1 {
    let line = lines[i]
    let match_result = regex.execute(line)
    if match_result.matched() { // Use execute and check matched()
      // Generate context
      let context_start = Int::max(0, i - context_lines)
      let context_end = Int::min(lines.length(), i + context_lines + 1)
      let context_lines_arr = []
      for j = context_start; j < context_end; j = j + 1 {
        context_lines_arr.push("\{j + 1}: \{lines[j]}")
      }
      let result = SearchResult::{
        context: context_lines_arr.join("\n"),
        line_number: i + 1,
        match_line: line.to_string(), // Convert StringView to String
        path: relative_path,
      }
      results.push(result)
    }
  }
  results
}

///|
/// Execute MoonBit IDE goto-definition command
async fn goto_definition(
  query : String,
  working_dir : String,
) -> String raise SearchError {
  let output = StringBuilder::new()
  let status = @spawn.spawn(
    "moon",
    ["ide", "goto-definition", query],
    stdout=output,
    stderr=output,
    cwd=working_dir,
  ) catch {
    error =>
      raise SearchError::MoonAnalysisError(query~, error=error.to_string())
  }
  if status != 0 {
    raise SearchError::MoonAnalysisError(
      query~,
      error="moon ide goto-definition failed with exit code \{status}",
    )
  }
  let result = output.to_string()
  if result.is_empty() {
    "No matching symbols found for query '\{query}'"
  } else {
    "Search completed using fuzzy symbolic search for MoonBit definitions.\nNote: The search pattern \"\{query}\" was used for fuzzy matching of symbol names.\n\n\{result}"
  }
}

///|
/// Execute MoonBit IDE find-references command
async fn find_references(
  query : String,
  working_dir : String,
) -> String raise SearchError {
  let output = StringBuilder::new()
  let status = @spawn.spawn(
    "moon",
    ["ide", "find-references", query],
    stdout=output,
    stderr=output,
    cwd=working_dir,
  ) catch {
    error =>
      raise SearchError::MoonAnalysisError(query~, error=error.to_string())
  }
  if status != 0 {
    raise SearchError::MoonAnalysisError(
      query~,
      error="moon ide find-references failed with exit code \{status}",
    )
  }
  let result = output.to_string()
  if result.is_empty() {
    "No references found for query '\{query}'"
  } else {
    "Search completed using MoonBit IDE find-references tool.\nQuery: \"\{query}\"\nWorking directory: \{working_dir}\n\n\{result}"
  }
}

///|
/// Check if path exists and get its type
async fn check_path(path : String) -> (Bool, Bool) { // (exists, is_file)
  try {
    match @fs.kind(path) {
      Regular => (true, true)
      Directory => (true, false)
      _ => (false, false)
    }
  } catch {
    _ => (false, false)
  }
}

///|
/// Structured search result for JSON output
priv struct SearchResultData {
  kind : SearchKind
  query : String
  path : String
  file_pattern : String
  context_lines : Int
  total_matches : Int
  results : Array[SearchResult]
  truncated : Bool
  message : String
} derive(ToJson, FromJson)

///|
/// Structured MoonBit tool result for JSON output
priv struct MoonbitToolResult {
  kind : SearchKind
  query : String
  path : String
  working_directory : String
  output : String
  message : String
} derive(ToJson, FromJson)

///|
/// Main tool implementation function
async fn search_files_impl(args : Json, cwd : String) -> @tool.Result noraise {
  // Extract parameters with validation
  match args {
    {
      "path": String(search_path),
      "regex": String(search_pattern),
      "kind": String(kind_str),
      ..
    } => {
      let context_lines = match args {
        { "context_lines": Number(cl, ..), .. } => Int::max(0, cl.to_int())
        _ => 2
      }
      let file_pattern = match args {
        { "file_pattern": String(fp), .. } => fp
        _ => "*"
      }

      // Parse search kind
      match SearchKind::from_string(kind_str) {
        Some(search_kind) => {
          // Resolve search path
          let absolute_search_path = if @path.is_absolute(search_path) {
            search_path
          } else {
            @path.join(cwd, search_path)
          }
          try {
            // Handle MoonBit symbol searches
            match search_kind {
              MoonbitDefinition => {
                let path_result = check_path(absolute_search_path)
                let exists = path_result.0
                let is_file = path_result.1
                if not(exists) {
                  @tool.error("Error: Directory not found: \{search_path}")
                } else if is_file {
                  @tool.error(
                    "Error: Path must be a directory for MoonBit definition search: \{search_path}",
                  )
                } else {
                  let output = goto_definition(
                    search_pattern, absolute_search_path,
                  )
                  let message = if output.contains("No matching symbols found") {
                    "No matching symbols found for query '\{search_pattern}'"
                  } else {
                    "Search completed using fuzzy symbolic search for MoonBit definitions."
                  }
                  let result = MoonbitToolResult::{
                    kind: search_kind,
                    query: search_pattern,
                    path: search_path,
                    working_directory: absolute_search_path,
                    output,
                    message,
                  }
                  @tool.ok(result.to_json())
                }
              }
              MoonbitReferences => {
                let path_result = check_path(absolute_search_path)
                let exists = path_result.0
                let is_file = path_result.1
                if not(exists) {
                  @tool.error("Error: Directory not found: \{search_path}")
                } else if is_file {
                  @tool.error(
                    "Error: Path must be a directory for MoonBit references search: \{search_path}",
                  )
                } else {
                  let output = find_references(
                    search_pattern, absolute_search_path,
                  )
                  let message = if output.contains("No references found") {
                    "No references found for query '\{search_pattern}'"
                  } else {
                    "Search completed using MoonBit IDE find-references tool."
                  }
                  let result = MoonbitToolResult::{
                    kind: search_kind,
                    query: search_pattern,
                    path: search_path,
                    working_directory: absolute_search_path,
                    output,
                    message,
                  }
                  @tool.ok(result.to_json())
                }
              }
              Regex => {
                // Validate path exists
                let path_result = check_path(absolute_search_path)
                let exists = path_result.0
                let is_file = path_result.1
                if not(exists) {
                  @tool.error("Error: Search path not found: \{search_path}")
                } else {
                  // Compile regex
                  let regex_result = @regexp.compile(search_pattern) catch {
                    error =>
                      return @tool.error("Invalid regex pattern: \{error}")
                  }

                  // Collect files to search
                  let files_to_search = if is_file {
                    [absolute_search_path]
                  } else {
                    collect_files_recursive(
                      absolute_search_path, file_pattern, cwd,
                    )
                  }

                  // Search through files
                  let all_results = []
                  for file_path in files_to_search {
                    let file_results = search_in_file(
                      file_path, regex_result, context_lines, cwd,
                    )
                    all_results.append(file_results)
                  }

                  // Limit to 200 results if needed
                  let truncated = all_results.length() > 200
                  let limited_results = if truncated {
                    let limited = []
                    for i = 0; i < 200; i = i + 1 {
                      limited.push(all_results[i])
                    }
                    limited
                  } else {
                    all_results
                  }
                  let message = if all_results.length() == 0 {
                    "No matches found."
                  } else if truncated {
                    "Search completed. Found \{all_results.length()} matches, showing only the first 200."
                  } else {
                    "Search completed. Found \{all_results.length()} matches."
                  }
                  let result = SearchResultData::{
                    kind: search_kind,
                    query: search_pattern,
                    path: search_path,
                    file_pattern,
                    context_lines,
                    total_matches: all_results.length(),
                    results: limited_results,
                    truncated,
                    message,
                  }
                  @tool.ok(result.to_json())
                }
              }
            }
          } catch {
            SearchError::FileReadError(path~, error~) =>
              @tool.error("Could not read file '\{path}': \{error}")
            SearchError::MoonAnalysisError(query~, error~) =>
              @tool.error(
                "Error performing MoonBit analysis for '\{query}': \{error}",
              )
            error => @tool.error("Error searching files: \{error}", error~)
          }
        }
        None =>
          @tool.error(
            "Error: Invalid search kind '\{kind_str}'. Must be 'regex', 'moonbit_definition', or 'moonbit_references'",
          )
      }
    }
    _ =>
      @tool.error("Error: 'path', 'regex' and 'kind' parameters are required")
  }
}

///|
/// Main search files tool implementation
pub fn new(cwd : String) -> @tool.Tool {
  @tool.tool(
    description="Search for patterns in files with three distinct modes: regex-based file content search, fuzzy symbolic search for MoonBit definitions, and MoonBit references search. This tool performs searches through files in the specified directory or file, displaying matches with context lines (configurable, default 2 lines before and after each match). Use 'regex' kind for traditional pattern matching in code/text, 'moonbit_definition' kind for finding MoonBit symbol definitions with fuzzy matching (symbol names can be imprecise), or 'moonbit_references' kind for finding all references to a MoonBit symbol.",
    name="search_files",
    parameters={
      "type": "object",
      "properties": {
        "context_lines": {
          "type": "number",
          "description": "Number of context lines to show before and after each match. Defaults to 2.",
          "default": 2,
        },
        "file_pattern": {
          "type": "string",
          "description": "Glob pattern to filter files (e.g., '*.ts', '*.js', '*.py', etc.). Defaults to '*' to search all files.",
          "default": "*",
        },
        "kind": {
          "type": "string",
          "enum": ["regex", "moonbit_definition", "moonbit_references"],
          "description": "The kind of search to perform. 'regex' performs traditional regex-based file content search. 'moonbit_definition' performs fuzzy symbolic search to find MoonBit symbol definitions - note that when using 'moonbit_definition', the regex parameter can be imprecise as the system will perform fuzzy search to find the most relevant symbols. 'moonbit_references' finds all references to a MoonBit symbol using the moon IDE tool.",
        },
        "path": {
          "type": "string",
          "description": "The path of the directory or file to search in, relative to the current working directory.",
        },
        "regex": {
          "type": "string",
          "description": "The search pattern. For 'regex' kind: regular expression pattern with full regex syntax. For 'moonbit_definition' kind: symbol name or partial name (can be imprecise) for fuzzy symbolic search.",
        },
      },
      "required": ["path", "regex", "kind"],
    },
    @tool.ToolFn(async fn(args) -> @tool.Result noraise {
      search_files_impl(args, cwd)
    }),
    render=result => try {
      // Try to parse as structured search result data (regex search)
      let search_data : SearchResultData = @json.from_json(result.output())
      // Handle regex search results
      if search_data.total_matches == 0 {
        return search_data.message
      }
      let formatted = []
      formatted.push(search_data.message)
      formatted.push("")
      for result in search_data.results {
        let header = "\{result.path}:\{result.line_number}"
        formatted.push("\{header}")
        formatted.push(result.context)
        formatted.push("")
      }
      formatted.join("\n")
    } catch {
      _ =>
        // Try to parse as MoonBit tool result (definition/references search)
        try {
          let moonbit_result : MoonbitToolResult = @json.from_json(
            result.output(),
          )
          let formatted = []
          formatted.push(moonbit_result.message)
          let query_value = moonbit_result.query
          formatted.push("Query: \"\{query_value}\"")
          let working_dir = moonbit_result.working_directory
          formatted.push("Working directory: \{working_dir}")
          formatted.push("")
          formatted.push(moonbit_result.output)
          formatted.join("\n")
        } catch {
          _ => "Error: Unexpected output format"
        }
    },
  )
}

///|
pub let prompt : String =
  #|# search_files
  #|
  #|## Purpose
  #|
  #|- Search for patterns in files with two distinct modes: regex-based file content
  #|  search and fuzzy symbolic search for MoonBit definitions
  #|- Performs searches through files in the specified directory, displaying matches
  #|  with context lines
  #|- **Specifically for MoonBit definition searches**: Use the `moonbit_definition`
  #|  kind for finding MoonBit symbol definitions with fuzzy matching
  #|
  #|## When to Use
  #|
  #|Use this tool in two main scenarios:
  #|
  #|### For General Pattern Searches (kind: "regex")
  #|
  #|- **Text pattern matching**: When you need to find specific code patterns,
  #|  comments, or documentation
  #|- **Multi-file searches**: Finding all occurrences of a pattern across multiple
  #|  files
  #|- **File content exploration**: Understanding how certain concepts are used
  #|  throughout the codebase
  #|- **Reference finding**: Locating all usages of a particular identifier or
  #|  pattern
  #|
  #|### For MoonBit Definition Searches (kind: "moonbit_definition")
  #|
  #|**This is the preferred approach for finding MoonBit symbols!**
  #|
  #|- **Finding function/method definitions**: When you need to see how a specific
  #|  MoonBit function is implemented
  #|- **Locating type definitions**: To understand the structure and implementation
  #|  of MoonBit structs, enums, or traits
  #|- **Variable/constant definitions**: Finding where specific MoonBit variables or
  #|  constants are declared
  #|- **API exploration**: Understanding how specific MoonBit APIs or library
  #|  functions are defined
  #|- **Code navigation**: Quickly jumping to the definition of a MoonBit symbol
  #|- **Understanding implementations**: Seeing the actual MoonBit code behind a
  #|  symbol name
  #|- **Common format**:
  #|  - 'fn @pkg.function': search for function or method defined in 'pkg' with name 'function'
  #|  - 'struct @pkg.Struct': search for struct 'Struct' defined in 'pkg'
  #|  - 'enum @pkg.Enum': search for enum 'Enum' defined in 'pkg'
  #|  - 'type @pkg.Type': search for type 'Type' defined in 'pkg'
  #|  - 'let @pkg.value': search for toplevel let defined 'value' in 'pkg'
  #|  - 'const @pkg.value': search for toplevel const defined 'value' in 'pkg'
  #|  - 'trait @pkg.Trait': search for trait 'Trait' defined in 'pkg'
  #|  - 'impl Trait for Type with method': search for 'method' of 'Trait' implemented by 'Type'
  #|
  #|## Important: MoonBit Definition Search
  #|
  #|**When you need to search for MoonBit definitions, always use `search_files` with `kind: "moonbit_definition"`**
  #|instead of other search methods. This provides fuzzy symbolic search
  #|specifically designed for MoonBit language constructs.
  #|
  #|## Parameters and Usage
  #|
  #|- **path**: The directory to search in
  #|- **regex**:
  #|  - For `kind: "regex"`: Traditional regex pattern
  #|  - For `kind: "moonbit_definition"`: **NOT a regex pattern!** This is a fuzzy
  #|    search query string (symbol name or partial name). The tool will perform
  #|    fuzzy matching to find symbols, so regex syntax like `|`, `*`, `+`, etc.
  #|    should NOT be used.
  #|- **kind**: Either `"regex"` or `"moonbit_definition"`
  #|- **file_pattern**: Optional glob pattern to filter files (e.g., '*.mbt')
  #|- **context_lines**: Number of context lines around matches (default: 2)
  #|
  #|## ⚠️ Critical: MoonBit Definition Search Query Format
  #|
  #|**When using `kind: "moonbit_definition"`, the `regex` parameter is NOT treated as a regular expression!**
  #|
  #|- ✅ **Correct**: `"regex": "Array::length"` - Simple symbol name
  #|- ✅ **Correct**: `"regex": "fib"` - Partial name for fuzzy matching
  #|- ✅ **Correct**: `"regex": "fibonacci"` - Full function name
  #|- ❌ **Incorrect**: `"regex": "fib|fibonacci"` - This will search for a symbol
  #|  literally named "fib|fibonacci", not symbols matching either "fib" OR
  #|  "fibonacci"
  #|- ❌ **Incorrect**: `"regex": "Array.*length"` - This will search for a symbol
  #|  literally containing "Array.*length", not symbols matching the pattern
  #|
  #|The fuzzy search will automatically find partial matches, so there's no need for
  #|regex syntax when using `moonbit_definition` kind.
  #|
  #|## Example Usage Scenarios
  #|
  #|### MoonBit Definition Search Examples
  #|
  #|User: I need to see how the Array::length method is defined.
  #|
  #|Assistant:
  #|
  #|I'll search for the Array::length definition using MoonBit definition search.
  #|(Issuing <search_files/> tool call with `kind` as `"moonbit_definition"` and
  #|`regex` as `"Array::length"`.)
  #|
  #|Tool:
  #|
  #|```plaintext
  #|Found 1 symbols match query 'Array::length':
  #|`Array::length` in builtin/arraycore_nonjs.mbt:77-80:
  #|77:#intrinsic("%array.length")
  #|78:pub fn[T] Array::length(self : Array[T]) -> Int {
  #|79:  self.len
  #|80:}
  #|```
  #|
  #|Assistant:
  #|
  #|I found the definition of the Array::length method:
  #|
  #|```moonbit
  #|#intrinsic("%array.length")
  #|pub fn[T] Array::length(self : Array[T]) -> Int {
  #|  self.len
  #|}
  #|```
  #|
  #|### Regex Search Examples
  #|
  #|User: Find all error handling patterns in the code.
  #|
  #|A: I'll search for error handling patterns using regex.
  #|
  #|Uses search_files with:
  #|
  #|- kind: "regex"
  #|- regex: "(try|catch|error|Error)"
  #|
  #|Search results omit for brevity.
  #|
