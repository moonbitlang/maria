///|
priv struct Params {
  patch : String
} derive(FromJson)

///|
fn format_result(result : ApplyResult) -> String {
  let json : Json = {
    "success": true,
    "message": result.summary(),
    "added": result.added,
    "modified": result.modified,
    "deleted": result.deleted,
  }
  json.stringify(indent=2)
}

///|
let schema : @tool.JsonSchema = {
  "type": "object",
  "properties": {
    "patch": {
      "type": "string",
      "description": "The V4A patch content. Format: *** Begin Patch\\n[file operations]\\n*** End Patch",
    },
  },
  "required": ["patch"],
}

///|
pub fn new(cwd : String) -> @tool.Tool[String] {
  @tool.new(
    name="apply_patch",
    description=(
      #|Apply structured file changes using V4A diff format.
      #|
      #|The patch format supports three operations:
      #|- *** Add File: <path> - Create a new file (lines prefixed with +)
      #|- *** Delete File: <path> - Remove an existing file
      #|- *** Update File: <path> - Modify a file using context-based diffs
      #|
      #|For Update File, use @@ markers with class/function context,
      #|and prefix lines with ' ' (context), '-' (remove), or '+' (add).
      #|
      #|Example:
      #|*** Begin Patch
      #|*** Update File: src/main.py
      #|@@ def greet():
      #| def greet():
      #|-    print("Hi")
      #|+    print("Hello, world!")
      #|*** End Patch
    ),
    schema~,
    async fn(args) -> @tool.ToolResult[String] noraise {
      let params : Params = @json.from_json(args) catch {
        err => return @tool.error("Invalid arguments: \{err}")
      }
      // Parse the patch
      let parsed = parse_patch(params.patch) catch {
        InvalidPatch(msg) => return @tool.error("Invalid patch: \{msg}")
        InvalidHunk(message~, line_number~) =>
          return @tool.error("Invalid hunk at line \{line_number}: \{message}")
      }
      // Apply the patch
      let result = apply_hunks(parsed.hunks[:], cwd) catch {
        ApplyError(msg) => return @tool.error("Failed to apply patch: \{msg}")
      }
      @tool.ok(format_result(result))
    },
  )
}

///|
pub let tool_instructions : String =
  #|## `apply_patch`
  #|
  #|Use the `apply_patch` tool to edit files using structured diffs.
  #|The patch format is a stripped-down, file-oriented diff format:
  #|
  #|*** Begin Patch
  #|[ one or more file sections ]
  #|*** End Patch
  #|
  #|Each operation starts with one of three headers:
  #|
  #|*** Add File: <path> - create a new file. Every following line is a + line.
  #|*** Delete File: <path> - remove an existing file. Nothing follows.
  #|*** Update File: <path> - patch an existing file in place.
  #|
  #|For Update File:
  #|- May be followed by *** Move to: <new path> to rename the file.
  #|- Then one or more "hunks", each introduced by @@ (optionally followed by context).
  #|- Within a hunk, each line starts with:
  #|  - ' ' (space) - context line (unchanged)
  #|  - '+' - added line
  #|  - '-' - removed line
  #|
  #|Context rules:
  #|- Show 3 lines of code immediately above and below each change.
  #|- Use @@ with class/function name if 3 lines is not unique.
  #|
  #|Example:
  #|*** Begin Patch
  #|*** Add File: hello.txt
  #|+Hello world
  #|*** Update File: src/app.py
  #|@@ def greet():
  #| def greet():
  #|-    print("Hi")
  #|+    print("Hello, world!")
  #|*** Delete File: obsolete.txt
  #|*** End Patch
  #|
  #|Important:
  #|- Include a header with your intended action (Add/Delete/Update)
  #|- Prefix new lines with `+` even when creating a new file
  #|- File paths must be relative, NEVER absolute
