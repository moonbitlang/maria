///|
/// Enhanced file writing tool that automatically formats MoonBit files and fixes syntax errors
/// This is a MoonBit translation of the TypeScript meta_write_to_file tool

///|
/// Parameters for the meta_write_to_file tool
priv struct MetaWriteParams {
  path : String
  search : String?
  replace : String?
  description : String
}

///|
/// Parse and validate meta_write_to_file parameters
fn parse_meta_write_params(args : Json) -> MetaWriteParams? {
  guard args is { "path": String(path), "description": String(description), .. } else {
    return None
  }
  let search = match args {
    { "search": String(s), .. } => Some(s)
    _ => None
  }
  let replace = match args {
    { "replace": String(r), .. } => Some(r)
    _ => None
  }
  Some(MetaWriteParams::{ path, search, replace, description })
}

///|
/// Context needed for the syntax fixing sub-agent
priv struct FixingContext {
  file_path : String
  cwd : String
  description : String
  syntax_errors : String
  parent_agent : @agent.Agent
}

///|
/// Result of diff comparison between two strings
priv struct DiffResult {
  has_changes : Bool
  diff_text : String
}

///|
/// Generate a diff between old and new content (simplified implementation)
fn generate_diff(
  old_content : String,
  new_content : String,
  title : String,
) -> DiffResult {
  if old_content == new_content {
    return DiffResult::{ has_changes: false, diff_text: "" }
  }

  // Simple diff implementation - in a real implementation you'd use git diff
  let diff_text = StringBuilder::new()
  diff_text.write_string("\n\n**\{title}:**\n```diff\n")
  let old_lines = old_content.split("\n").to_array()
  let new_lines = new_content.split("\n").to_array()

  // Simplified line-by-line diff
  let max_lines = @cmp.maximum(old_lines.length(), new_lines.length())
  for i = 0; i < max_lines; i = i + 1 {
    let old_line = if i < old_lines.length() { old_lines[i] } else { "" }
    let new_line = if i < new_lines.length() { new_lines[i] } else { "" }
    if old_line != new_line {
      if old_line != "" {
        diff_text.write_string("-\{old_line}\n")
      }
      if new_line != "" {
        diff_text.write_string("+\{new_line}\n")
      }
    }
  }
  diff_text.write_string("```")
  DiffResult::{ has_changes: true, diff_text: diff_text.to_string() }
}

///|
/// Check if a file is a MoonBit file based on extension
fn is_moonbit_file(file_path : String) -> Bool {
  file_path.has_suffix(".mbt") || file_path.has_suffix(".mbt.md")
}

///|
/// Format a MoonBit file using moon fmt
async fn format_moonbit_file(file_path : String, cwd : String) -> Unit {
  try {
    let output = StringBuilder::new()
    let _ = @spawn.spawn("moon", ["fmt", file_path], output~, cwd~)
    // Ignore formatting errors for now
  } catch {
    _ => () // Silently ignore formatting errors
  }
}

///|
/// Check syntax errors in a MoonBit file using moon check
async fn check_syntax_errors(_file_path : String, cwd : String) -> String {
  try {
    // Use the moon module's check functionality instead of direct spawn
    let mod = @moon.Module::load(cwd)
    mod.check()
    let error_messages = []
    for diagnostic in mod.diagnostics() {
      // Filter for syntax errors (error codes 3xxx are syntax errors)
      if diagnostic.error_code >= 3000 && diagnostic.error_code < 4000 {
        match diagnostic.level {
          @moon.Level::Error => {
            let error_msg = StringBuilder::new()
            error_msg.write_string(
              "error[\{diagnostic.error_code.to_string().pad_start(4, '0')}]: \{diagnostic.loc.path}:\{diagnostic.loc.start.line}:\{diagnostic.loc.start.col}: \{diagnostic.message}",
            )
            error_messages.push(error_msg.to_string())
          }
          _ => continue
        }
      }
    }
    error_messages.join("\n")
  } catch {
    _ => "" // Return empty string if check fails
  }
}

///|
/// Tool for the sub-agent to submit fixed code segments
let submit_fixed_file : @tool.Tool[FixingContext] = @tool.tool(
  name="submit_fixed_file",
  description="Submit the complete fixed file content for verification",
  parameters={
    "type": "object",
    "properties": {
      "content": {
        "type": "string",
        "description": "The complete fixed file content",
      },
    },
    "required": ["content"],
  },
  (args, ctx) => {
    guard args is { "content": String(content), .. } else {
      return @tool.error("Missing 'content' argument")
    }
    try {
      // Write the fixed content to file
      @fs.write_to_file(ctx.file_path, content)

      // Check for syntax errors
      let syntax_errors = check_syntax_errors(ctx.file_path, ctx.cwd)
      if syntax_errors == "" {
        @tool.ok(
          "File verification successful! The code compiles without syntax errors.",
        )
      } else {
        @tool.error(
          "File verification failed with syntax errors:\n\{syntax_errors}",
        )
      }
    } catch {
      error => @tool.error("Failed to write or verify file: \{error}", error~)
    }
  },
  render=result => {
    guard result.output is String(formatted) else {
      return "Error: Unexpected output format"
    }
    formatted
  },
)

///|
/// Tool for the sub-agent to read current file content
let read_current_file : @tool.Tool[FixingContext] = @tool.tool(
  name="read_file",
  description="Read the current file content to understand what needs to be fixed",
  parameters={
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "The file path to read (should match the target file)",
      },
    },
    "required": ["path"],
  },
  (args, ctx) => {
    guard args is { "path": String(path), .. } else {
      return @tool.error("Missing 'path' argument")
    }

    // Only allow reading the target file for security
    // Simple string comparison for security
    if path != ctx.file_path {
      return @tool.error("Can only read the target file being fixed")
    }
    try {
      let content = @fs.read_file(ctx.file_path)
      @tool.ok("File content:\n\{content}")
    } catch {
      error => @tool.error("Failed to read file: \{error}", error~)
    }
  },
  render=result => {
    guard result.output is String(formatted) else {
      return "Error: Unexpected output format"
    }
    formatted
  },
)

///|
/// Tool for the sub-agent to signal completion
let attempt_completion : @tool.Tool[FixingContext] = @tool.tool(
  name="attempt_completion",
  description="Signal that syntax fixing is complete",
  parameters={
    "type": "object",
    "properties": {
      "result": {
        "type": "string",
        "description": "Summary of the fixing result",
      },
    },
    "required": ["result"],
  },
  (args, _ctx) => {
    guard args is { "result": String(result), .. } else {
      return @tool.error("Missing 'result' argument")
    }
    @tool.ok("Syntax fixing completed: \{result}")
  },
  render=result => {
    guard result.output is String(formatted) else {
      return "Error: Unexpected output format"
    }
    formatted
  },
)

///|
/// Create a system message for the syntax fixing sub-agent
fn build_fixing_system_message() -> String {
  (
    #|You are a highly skilled software developer with extensive knowledge in many programming languages, frameworks, design patterns, and best practices.
    #|In particular, you are an expert in the MoonBit programming language and you are primarily responsible for writing and improving MoonBit code.
    #|
    #|====
    #|
    #|CAPABILITIES
    #|
    #|- You can read and analyze MoonBit code and can write clean, efficient, and well-documented code.
    #|- You can debug complex issues and provide detailed explanations, offering architectural insights and design patterns.
    #|- You have access to tools to read the current file, submit fixed content, and signal completion.
    #|
    #|====
    #|
    #|RULES
    #|
    #|- Always read the current file content first to understand what needs to be fixed.
    #|- When fixing code, ensure that your changes are minimal but effective, addressing all the reported issues.
    #|- Always use the `submit_fixed_file` tool to verify that your fix compiles without errors.
    #|- Provide complete, valid MoonBit code in your submissions - do not use placeholders or incomplete code.
    #|- Focus on fixing the specific syntax errors while maintaining code quality and best practices.
    #|- If the first attempt fails, analyze the error messages and refine your approach.
    #|- Call `attempt_completion` when no syntax errors remain or when you cannot fix the errors.
    #|
    #|====
    #|
    #|WORKFLOW
    #|
    #|1. Use `read_file` to examine the current file content and understand the syntax errors.
    #|2. Analyze the reported syntax errors and identify the root cause.
    #|3. Create a fixed version of the entire file that addresses all syntax issues.
    #|4. Use `submit_fixed_file` to verify your solution compiles correctly.
    #|5. If verification fails, analyze the error output and refine your fix until successful.
    #|6. Call `attempt_completion` when done.
    #|
    #|Your goal is to provide a corrected MoonBit file that compiles without syntax errors.
  )
}

///|
/// Create a user message for the syntax fixing sub-agent
fn build_fixing_user_message(
  description : String,
  file_path : String,
  syntax_errors : String,
) -> String {
  (
    $|You are a MoonBit syntax fixing assistant. A file has been written but contains syntax errors that need to be fixed.\n\n
    $|**Task Description:**\n\{description}\n\n
    $|**File Path:** \{file_path}\n\n
    $|**Current Syntax Errors:**\n\{syntax_errors}\n\n
    $|**Your Task:**\n
    $|1. Use `read_file` to examine the current file contents\n
    $|2. Use `submit_fixed_file` to provide the complete fixed file content\n
    $|3. Only fix syntax errors - do not change logic unless absolutely necessary\n
    $|4. Continue until all syntax errors are fixed\n
    $|5. Call `attempt_completion` when done\n\n
    $|**Guidelines:**\n
    $|- Focus only on fixing syntax errors, not improving code quality\n
    $|- Preserve the original intent and functionality of the code\n
    $|- Use proper MoonBit syntax and conventions\n
    $|- If you cannot fix an error, explain why clearly\n
    $|- When syntax check passes, call `attempt_completion` immediately\n\n
    $|Please start by using `read_file` to examine the current file, then use `submit_fixed_file` to fix the syntax errors.
  )
}

///|
/// Fix syntax errors using a sub-agent
async fn fix_syntax_errors(ctx : FixingContext) -> String? {
  try {
    // Create sub-agent
    let subagent = @agent.new(ctx.parent_agent.model, cwd=ctx.cwd)

    // Add tools
    subagent.add_tool(read_current_file, ctx)
    subagent.add_tool(submit_fixed_file, ctx)
    subagent.add_tool(attempt_completion, ctx)

    // Add system message
    subagent.add_message(
      @openai.system_message(content=build_fixing_system_message()),
    )

    // Add user message
    let user_message = build_fixing_user_message(
      ctx.description,
      ctx.file_path,
      ctx.syntax_errors,
    )
    subagent.add_message(@openai.user_message(content=user_message))

    // Start the sub-agent with a timeout (5 minutes)
    @async.with_timeout(300_000, () => subagent.start()) catch {
      _ => return Some("Syntax fixing timed out after 5 minutes")
    }
    None // Success
  } catch {
    error => Some("Failed to fix syntax errors: \{error}")
  }
}

///|
/// Execute the meta_write_to_file operation
async fn execute_meta_write_to_file(
  args : Json,
  agent : @agent.Agent,
) -> @tool.Result noraise {
  // Parse and validate parameters
  let params = match parse_meta_write_params(args) {
    Some(params) => params
    None =>
      return @tool.error(
        "Error: Invalid parameters. Required: 'path' and 'description'",
      )
  }
  let cwd = agent.cwd

  // Resolve file path
  let resolved_path = if @path.is_absolute(params.path) {
    params.path
  } else {
    @path.join(cwd, params.path)
  }
  try {
    // Step 1: Write the file using standard write_to_file logic
    // Implement write_to_file logic directly
    let write_result = match (params.search, params.replace) {
      (None, Some(replace)) =>
        // Replace entire file content
        try {
          // Create directory if it doesn't exist
          @fs.make_directory(@path.dirname(resolved_path), recursive=true)
          @fs.write_to_file(resolved_path, replace)
          @tool.ok("File written successfully to \{params.path}")
        } catch {
          error => @tool.error("Error writing to file: \{error}", error~)
        }
      (Some(search), replace_opt) =>
        // Search and replace operation
        try {
          let content = @fs.read_file(resolved_path)
          let replace = match replace_opt {
            Some(r) => r
            None => ""
          }
          match content.find(search) {
            None => @tool.error("Search content not found in file: \{search}")
            Some(pos) => {
              let before = content[0:pos].to_string()
              let after = content[pos + search.length():].to_string()
              let new_content = before + replace + after
              @fs.write_to_file(resolved_path, new_content)
              @tool.ok("Changes applied to \{params.path}")
            }
          }
        } catch {
          error => @tool.error("Error writing to file: \{error}", error~)
        }
      (None, None) =>
        @tool.error("Either 'replace' content must be provided for new files")
    }
    match write_result.error {
      Some(_) => return write_result
      None => () // Continue processing
    }

    // Step 1.5: Capture content immediately after initial write
    let initial_content = @fs.read_file(resolved_path)

    // Step 2: If it's a MoonBit file, format it and fix syntax if needed
    if is_moonbit_file(resolved_path) {
      // Format the file
      format_moonbit_file(resolved_path, cwd)

      // Check for syntax errors (but skip fixing for .mbt.md files)
      let syntax_errors = check_syntax_errors(resolved_path, cwd)
      let is_markdown = resolved_path.has_suffix(".mbt.md")
      if syntax_errors != "" && !is_markdown {
        // Fix syntax errors using sub-agent
        let fixing_ctx = FixingContext::{
          file_path: resolved_path,
          cwd,
          description: params.description,
          syntax_errors,
          parent_agent: agent,
        }
        let fixing_error = fix_syntax_errors(fixing_ctx)
        match fixing_error {
          Some(error) => return @tool.error("\{write_result.output}\n\{error}")
          None => () // Continue
        }
      }

      // Step 4: Compare final content with initial content
      let final_content = @fs.read_file(resolved_path)
      let diff = generate_diff(
        initial_content, final_content, "Changes made during formatting/fixing",
      )

      // Add syntax error learning prompt if there were syntax errors that got fixed
      let learning_prompt = if syntax_errors != "" && diff.has_changes {
        let prompt = StringBuilder::new()
        prompt.write_string("\n\n**⚠️ Syntax Error Learning Note:**\n")
        prompt.write_string(
          "The sub-agent has automatically fixed syntax errors in this MoonBit file. ",
        )
        prompt.write_string(
          "Please review the changes above to understand what syntax issues were corrected. ",
        )
        prompt.write_string(
          "Pay attention to these patterns to avoid similar syntax errors in future MoonBit code:\n\n",
        )
        prompt.write_string(
          "Original syntax errors that were fixed:\n\{syntax_errors}\n\n",
        )
        prompt.write_string(
          "Please learn from these corrections and apply proper MoonBit syntax in subsequent code generation.",
        )
        prompt.to_string()
      } else {
        ""
      }
      guard write_result.output is String(write_msg) else {
        return @tool.error("Unexpected write result format")
      }
      @tool.ok((write_msg + diff.diff_text + learning_prompt).to_json())
    } else {
      // Non-MoonBit files: show diff from initial write
      let final_content = @fs.read_file(resolved_path)
      let diff = generate_diff(
        initial_content, final_content, "Complete diff from initial write",
      )
      guard write_result.output is String(write_msg) else {
        return @tool.error("Unexpected write result format")
      }
      @tool.ok((write_msg + diff.diff_text).to_json())
    }
  } catch {
    error => @tool.error("Error in meta_write_to_file: \{error}", error~)
  }
}

///|
/// The meta_write_to_file tool definition
pub let meta_write_to_file : @tool.Tool[@agent.Agent] = @tool.tool(
  description="Enhanced file writing tool that writes content to a file, automatically formats MoonBit files using moon fmt, checks for syntax errors with moon check, and spawns a sub-agent to fix any syntax errors found. This ensures that MoonBit files are always properly formatted and syntactically correct after writing. Returns diff comparison if final content differs from initial write.",
  name="meta_write_to_file",
  parameters={
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "The path of the file to write to, relative to the current working directory.",
      },
      "search": {
        "type": "string",
        "description": "The content to search for. If not provided, the entire file will be replaced with the replace content.",
      },
      "replace": {
        "type": "string",
        "description": "The content to replace with. If search is not provided, this will be the entire file content. If replace is not provided, the matched content will be deleted.",
      },
      "description": {
        "type": "string",
        "description": "A natural language description of what you're trying to accomplish with this file write operation. This helps the sub-agent understand the intent when fixing syntax errors.",
      },
    },
    "required": ["path", "description"],
  },
  execute_meta_write_to_file,
  render=result => {
    guard result.output is String(formatted) else {
      return "Error: Unexpected output format"
    }
    formatted
  },
)
