///|
/// Enhanced file writing tool that automatically formats MoonBit files and fixes syntax errors
/// This is a MoonBit translation of the TypeScript meta_write_to_file tool

///|
/// Check if a file is a MoonBit file based on extension
fn is_moonbit_file(file_path : String) -> Bool {
  file_path.has_suffix(".mbt")
}

///|
/// Format a MoonBit file using moon fmt
async fn format_moonbit_source(source : String) -> String noraise {
  @moon.format_string(source) catch {
    _ => source // Return original source if formatting fails
  }
}

///|
const DiagnosticLimit : Int = 10

///|
async fn render_diagnostics(
  path~ : String,
  content : String,
  diagnostics : Array[@moon.Diagnostic],
) -> String {
  let overlay = {}
  overlay[@path.basename(path).to_string()] = content
  @moon.render_diagnostics(
    diagnostics,
    context=1,
    limit=DiagnosticLimit,
    overlay~,
  )
}

///|
/// Tool for the sub-agent to submit fixed code segments
let submit_schema : @tool.JsonSchema = @tool.JsonSchema::from_json({
  "type": "object",
  "properties": {
    "content": {
      "type": "string",
      "description": "The complete fixed file content",
    },
  },
  "required": ["content"],
})

///|
fn submit_fixed_file_new(ctx : FixingContext) -> @tool.Tool[String] {
  @tool.new(
    name="submit_fixed_file",
    description="Submit the complete fixed file content for verification",
    schema=submit_schema,
    async fn(args) -> @tool.ToolResult[String] noraise {
      guard args is { "content": String(content), .. } else {
        return @tool.error("Missing 'content' argument")
      }
      try {
        // Write the fixed content to file
        let diagnostics = @moon.check_syntax_of_string(path=ctx.path, content)
        if diagnostics.is_empty() {
          ctx.content = content
          @tool.ok(
            "File verification successful! The code compiles without syntax errors.",
          )
        } else {
          let syntax_errors = render_diagnostics(
            path=ctx.path,
            content,
            diagnostics,
          )
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
/// Tool for the sub-agent to signal completion
let completion_schema : @tool.JsonSchema = @tool.JsonSchema::from_json({
  "type": "object",
  "properties": {
    "result": {
      "type": "string",
      "description": "Summary of the fixing result",
    },
  },
  "required": ["result"],
})

///|
fn attempt_completion_new(ctx : FixingContext) -> @tool.Tool[String] {
  @tool.new(
    name="attempt_completion",
    description="Signal that syntax fixing is complete",
    schema=completion_schema,
    async fn(args) -> @tool.ToolResult[String] noraise {
      guard args is { "result": String(result), .. } else {
        return @tool.error("Missing 'result' argument")
      }
      ctx.result = Some(result)
      @tool.ok("Syntax fixing completed successfully.")
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
  file_content : String,
  syntax_errors : String,
) -> String {
  (
    $|You are a MoonBit syntax fixing assistant. A file has been written but contains syntax errors that need to be fixed.\n\n
    $|**Task Description:**
    $|
    $|\{description}
    $|
    $|**File Content:**
    $|
    $|```moonbit
    $|\{file_content}
    $|```
    $|
    $|**Current Syntax Errors:**
    $|
    $|\{syntax_errors}
    $|
    $|**Your Task:**
    $|
    $|1. Analyze the syntax errors and understand what needs to be fixed
    $|2. Use `submit_fixed_file` to provide the complete fixed file content
    $|3. Only fix syntax errors - do not change logic unless absolutely necessary
    $|4. Continue until all syntax errors are fixed
    $|5. Call `attempt_completion` when done
    $|
    $|**Guidelines:**
    $|
    $|- Focus only on fixing syntax errors, not improving code quality
    $|- Preserve the original intent and functionality of the code, as much as possible
    $|- Use proper MoonBit syntax and conventions
    $|- If you cannot fix an error, explain why clearly
    $|- When syntax check passes, call `attempt_completion` immediately
  )
}

///|
/// Fix syntax errors using a sub-agent
async fn fix_syntax_errors(ctx : FixingContext) -> Unit {
  // Create sub-agent
  let subagent = @agent.new(
    ctx.parent_agent.model,
    logger=ctx.parent_agent.logger.child({
      "tool": {
        "name": "meta_write_to_file",
        "id": ctx.parent_agent.uuid.v4().to_json(),
      },
    }),
    cwd=ctx.cwd,
  )

  // Add tools using factory functions
  subagent.add_tools([
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
    ctx.content,
    ctx.syntax_errors,
  )
  subagent.add_message(@openai.user_message(content=user_message))

  // Start the sub-agent with a timeout (5 minutes)
  @async.with_timeout(300_000, () => subagent.start())
}

///|
async fn execute_replace_in_file(
  params : MetaWriteParams,
  resolved_path : String,
) -> @tool.ToolResult[String] noraise {
  match (params.search, params.replace) {
    (None, Some(replace)) =>
      try {
        mkdir_then_write(resolved_path, replace)
        @tool.ok("File written successfully to \{params.path}")
      } catch {
        error => @tool.error("Error writing to file: \{error}", error~)
      }
    (Some(search), replace_opt) =>
      try {
        let content = @fs.read_file(resolved_path)
        let replace = match replace_opt {
          Some(r) => r
          None => ""
        }
        // TODO: unify search strategy with replace_in_file tool
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
}

///|
async fn mkdir_then_write(path : String, content : String) -> Unit {
  @fs.make_directory(@path.dirname(path), recursive=true, exists_ok=true)
  @fs.write_to_file(path, content)
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
  let resolved_path = if @path.is_absolute(params.path) {
    params.path
  } else {
    @path.join(cwd, params.path)
  }
  try {
    // If it's a MoonBit file, format it and fix syntax if needed
    if is_moonbit_file(resolved_path) {
      // Calculate initial content by applying search/replace
      let initial_content = match (params.search, params.replace) {
        (None, Some(replace)) => replace
        (Some(search), replace_opt) => {
          let file_content = @fs.read_file(resolved_path)
          let replace = match replace_opt {
            Some(r) => r
            None => ""
          }
          match file_content.find(search) {
            None =>
              return @tool.error("Search content not found in file: \{search}")
            Some(pos) => {
              let before = file_content[0:pos].to_string()
              let after = file_content[pos + search.length():].to_string()
              before + replace + after
            }
          }
        }
        (None, None) =>
          return @tool.error(
            "Either 'replace' content must be provided for new files",
          )
      }

      // Format the source, even if there are syntax errors, as some syntax
      // errors can be auto-corrected by the formatter.
      let formatted_content = format_moonbit_source(initial_content)

      // Check for syntax errors (but skip fixing for .mbt.md files)
      let diagnostics = @moon.check_syntax_of_string(
        // Use params.path for better readability in diagnostics
        path=params.path,
        formatted_content,
      )

      // If there is no syntax error, write the file and return
      if diagnostics.is_empty() {
        mkdir_then_write(resolved_path, formatted_content)
        let diff = generate_diff(
          initial_content, formatted_content, "Changes made during formatting",
        )
        return @tool.ok(MetaWriteToFileResult::{
          path: resolved_path,
          message: if params.search is Some(_) {
            "Changes applied and formatted successfully to \{params.path}"
          } else {
            "File written and formatted successfully to \{params.path}"
          },
          diff: diff.diff_text,
          learning_prompt: None,
        })
      }

      // If there are syntax errors, fix them using sub-agent
      let syntax_errors = render_diagnostics(
        path=params.path,
        formatted_content,
        diagnostics,
      )
      let fixing_ctx = FixingContext::{
        path: params.path,
        cwd,
        result: None,
        content: formatted_content,
        description: params.description,
        syntax_errors,
        parent_agent: agent,
      }
      fix_syntax_errors(fixing_ctx) catch {
        error =>
          return @tool.error("Failed to fix syntax errors: \{error}", error~)
      }

      // Re-format the file after fixing syntax errors
      let final_content = format_moonbit_source(fixing_ctx.content)

      // Write final content to file
      mkdir_then_write(resolved_path, final_content)

      // Compare final content with initial content and generate diff
      let diff = generate_diff(
        initial_content, final_content, "Changes made during formatting/fixing",
      )

      // Add syntax error learning prompt if there were syntax errors that got fixed
      let learning_prompt = if syntax_errors != "" && diff.has_changes {
        let prompt =
          $|**⚠️ Syntax Error Learning Note:**
          $|
          $|The sub-agent has automatically fixed syntax errors in this MoonBit file.
          $|Please review the changes to understand what syntax issues were corrected.
          $|Pay attention to these patterns to avoid similar syntax errors in future MoonBit code:
          $|
          $|Original syntax errors that were fixed:
          $|
          $|\{syntax_errors}
          $|
          $|Summary of fixes applied:
          $|
          $|\{fixing_ctx.result.unwrap_or_default()}
        prompt
      } else {
        ""
      }
      @tool.ok(MetaWriteToFileResult::{
        path: resolved_path,
        message: if params.search is Some(_) {
          "Changes applied and formatted successfully to \{params.path}"
        } else {
          "File written and formatted successfully to \{params.path}"
        },
        diff: diff.diff_text,
        learning_prompt: match learning_prompt {
          "" => None
          learning_prompt => Some(learning_prompt)
        },
      })
    } else {
      // Non-MoonBit files: call replace_in_file directly
      let write_result : @tool.ToolResult[String] = execute_replace_in_file(
        params, resolved_path,
      )

      // Return early if write failed
      let write_result = match write_result {
        Error(error, message) => return @tool.error(message, error~)
        Ok(write_result) => write_result
      }
      @tool.ok(MetaWriteToFileResult::{
        path: resolved_path,
        message: write_result,
        diff: "",
        learning_prompt: None,
      })
    }
  } catch {
    error => @tool.error("Error in meta_write_to_file: \{error}", error~)
  }
}

///|
/// The meta_write_to_file tool definition
let meta_schema : @tool.JsonSchema = @tool.JsonSchema::from_json({
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
})

///|
pub fn new(agent : @agent.Agent) -> @tool.Tool[MetaWriteToFileResult] {
  @tool.new(
    description="Enhanced file writing tool that writes content to a file, automatically formats MoonBit files using moon fmt, checks for syntax errors with moon check, and spawns a sub-agent to fix any syntax errors found. This ensures that MoonBit files are always properly formatted and syntactically correct after writing. Returns diff comparison if final content differs from initial write.",
    name="meta_write_to_file",
    schema=meta_schema,
    async fn(args) -> @tool.ToolResult[MetaWriteToFileResult] noraise {
      execute_meta_write_to_file(args, agent)
    },
  )
}
