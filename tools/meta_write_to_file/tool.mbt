///|
/// Enhanced file writing tool that automatically formats MoonBit files and fixes syntax errors
/// This is a MoonBit translation of the TypeScript meta_write_to_file tool

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
    let _ = @spawn.spawn(
      "moon",
      ["fmt", file_path],
      stdout=output,
      stderr=output,
      cwd~,
    )
    // Ignore formatting errors for now
  } catch {
    _ => () // Silently ignore formatting errors
  }
}

///|
/// Check syntax errors in a MoonBit file using moon check
async fn check_syntax_errors(_file_path : String, cwd : String) -> String {
  let error_messages = []
  try {
    // Use the moon module's check functionality instead of direct spawn
    let mod = @moon.Module::load(cwd)
    mod.check()
    for diagnostic in mod.diagnostics() {
      // Filter for syntax errors (error codes 3xxx are syntax errors)
      if diagnostic.error_code is (3000..<4000) && diagnostic.level is Error {
        let error_msg = "error[\{diagnostic.error_code.to_string().pad_start(4, '0')}]: \{diagnostic.loc.path}:\{diagnostic.loc.start.line}:\{diagnostic.loc.start.col}: \{diagnostic.message}"
        error_messages.push(error_msg)
      }
    }
  } catch {
    _ => () // Return empty string if check fails
  }
  error_messages.join("\n")
}

///|
/// Tool for the sub-agent to submit fixed code segments
fn submit_fixed_file_new(ctx : FixingContext) -> @tool.Tool[String] {
  @tool.new(
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
    async fn(args) -> @tool.ToolResult[String] noraise {
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
  )
}

///|
/// Tool for the sub-agent to read current file content
fn read_current_file_new(ctx : FixingContext) -> @tool.Tool[String] {
  @tool.new(
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
    @tool.ToolFn(async fn(args) -> @tool.ToolResult[String] noraise {
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
    }),
  )
}

///|
/// Tool for the sub-agent to signal completion
fn attempt_completion_new(_ : FixingContext) -> @tool.Tool[String] {
  @tool.new(
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
    async fn(args) -> @tool.ToolResult[String] noraise {
      guard args is { "result": String(result), .. } else {
        return @tool.error("Missing 'result' argument")
      }
      @tool.ok("Syntax fixing completed: \{result}")
    },
  )
}

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
    $|- Preserve the original intent and functionality of the code, as much as possible\n
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

    // Add tools using factory functions
    subagent.add_tools([
      read_current_file_new(ctx).to_agent_tool(),
      submit_fixed_file_new(ctx).to_agent_tool(),
      attempt_completion_new(ctx).to_agent_tool(),
    ])

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
) -> @tool.ToolResult[MetaWriteToFileResult] noraise {
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
    let write_result : @tool.ToolResult[String] = match
      (params.search, params.replace) {
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
    // if write_result is Error(_, _) {
    let write_result = match write_result {
      Error(error, message) => return @tool.error(message, error~) // Return early on error
      Ok(write_result) => write_result
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
        if fixing_error is Some(error) {
          return @tool.error("\{write_result}\n\{error}")
        }
      }

      // Step 3: Re-format the file after fixing
      format_moonbit_file(resolved_path, cwd)

      // Step 4: Compare final content with initial content
      let final_content = @fs.read_file(resolved_path)
      let diff = generate_diff(
        initial_content, final_content, "Changes made during formatting/fixing",
      )

      // Add syntax error learning prompt if there were syntax errors that got fixed
      let learning_prompt = if syntax_errors != "" && diff.has_changes {
        let prompt =
          $|
          $|
          $|**⚠️ Syntax Error Learning Note:**
          $|The sub-agent has automatically fixed syntax errors in this MoonBit file.
          $|Please review the changes above to understand what syntax issues were corrected.
          $|Pay attention to these patterns to avoid similar syntax errors in future MoonBit code:
          $|
          $|Original syntax errors that were fixed:
          $|\{syntax_errors}
          $|
          $|Please learn from these corrections and apply proper MoonBit syntax in subsequent code generation.
          $|
        prompt
      } else {
        ""
      }
      @tool.ok(MetaWriteToFileResult::{
        path: resolved_path,
        message: write_result,
        diff: diff.diff_text,
        learning_prompt: match learning_prompt {
          "" => None
          learning_prompt => Some(learning_prompt)
        },
      })
    } else {
      // Non-MoonBit files: show diff from initial write
      let final_content = @fs.read_file(resolved_path)
      let diff = generate_diff(
        initial_content, final_content, "Complete diff from initial write",
      )
      @tool.ok(MetaWriteToFileResult::{
        path: resolved_path,
        message: write_result,
        diff: diff.diff_text,
        learning_prompt: None,
      })
    }
  } catch {
    error => @tool.error("Error in meta_write_to_file: \{error}", error~)
  }
}

///|
/// The meta_write_to_file tool definition
pub fn new(agent : @agent.Agent) -> @tool.Tool[MetaWriteToFileResult] {
  @tool.new(
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
    (async fn(
      args,
    ) -> @tool.ToolResult[MetaWriteToFileResult] noraise {
      execute_meta_write_to_file(args, agent)
    }),
  )
}
