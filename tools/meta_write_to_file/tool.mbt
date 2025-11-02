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
  diagnostics : @diagnostics.Diagnostics,
) -> String {
  let overlay = {}
  overlay[@path.basename(path).to_string()] = content
  diagnostics.render(
    context=1,
    limit=DiagnosticLimit,
    overlay~,
  )
}

///|
fn submit_fixed_file_new(ctx : FixingContext) -> @tool.Tool[String] {
  @tool.new(
    name="submit_fixed_file",
    description="Submit the complete fixed file content for verification",
    schema=submit_schema,
    async fn(args) -> @tool.ToolResult[String] noraise {
      let { content } : InputSubmit = @json.from_json(args) catch {
        err =>
          return @tool.error(
            "Invalid arguments provided to submit_fixed_file: \{err}",
          )
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
fn attempt_completion_new(ctx : FixingContext) -> @tool.Tool[String] {
  @tool.new(
    name="attempt_completion",
    description="Signal that syntax fixing is complete",
    schema=completion_schema,
    async fn(args) -> @tool.ToolResult[String] noraise {
      let { result } : InputCompletion = @json.from_json(args) catch {
        err =>
          return @tool.error(
            "Invalid arguments provided to attempt_completion: \{err}",
          )
      }
      ctx.result = Some(result)
      @tool.ok("Syntax fixing completed successfully.")
    },
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
    $|1. ONLY FIX SYNTAX ERRORS - DO NOT CHANGE THE BEHAVIOR
    $|2. Analyze the syntax errors and understand what needs to be fixed
    $|   All syntax errors are already reported, don't try to fix syntax errors not reported,
    $|   it may be your hallucination if you think there are more syntax errors.
    $|3. Use `submit_fixed_file` to provide the complete fixed file content    
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
    @openai.system_message(content=syntax_error_expert_prompt),
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
  let replace = params.replace
  match params.search {
    None =>
      try {
        mkdir_then_write(resolved_path, replace)
        @tool.ok("File written successfully to \{params.path}")
      } catch {
        error => @tool.error("Error writing to file: \{error}", error~)
      }
    Some(search) =>
      try {
        let content = @fs.read_file(resolved_path)
        match @fuzzy.find_match(content, search) {
          None => @tool.error("Search content not found in file: \{search}")
          Some(match_result) => {
            let before = content[0:match_result.position].to_string()
            let after = content[match_result.position + match_result.length:].to_string()
            let new_content = before + replace + after
            @fs.write_to_file(resolved_path, new_content)
            @tool.ok("Changes applied to \{params.path}")
          }
        }
      } catch {
        error => @tool.error("Error writing to file: \{error}", error~)
      }
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
  let params : MetaWriteParams = @json.from_json(args) catch {
    error =>
      return @tool.error(
        "Error: Invalid arguments provided to meta_write_to_file tool: \{error}",
        error~,
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
      let replace = params.replace
      let initial_content = match params.search {
        None => replace
        Some(search) => {
          let file_content = @fs.read_file(resolved_path)
          match @fuzzy.find_match(file_content, search) {
            None =>
              return @tool.error("Search content not found in file: \{search}")
            Some(match_result) => {
              let before = file_content[0:match_result.position].to_string()
              let after = file_content[match_result.position +
              match_result.length:].to_string()
              before + replace + after
            }
          }
        }
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
      @tool.ok({
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
      @tool.ok({
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
