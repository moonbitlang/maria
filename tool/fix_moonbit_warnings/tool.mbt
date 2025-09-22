///|
async fn render_diagnostics(
  diagnostics : Array[@moon.Diagnostic],
  limit~ : Int,
  overlay? : Map[String, String] = {},
) -> String noraise {
  let cache = {}
  for k, v in overlay {
    cache[k] = v.split("\n").collect()
  }
  let errors = @deque.new()
  let warnings = @deque.new()
  for d in diagnostics {
    match d.level {
      Error => errors.push_back(d)
      Warning => warnings.push_back(d)
    }
  }
  let limited_diagnostics = []
  while limited_diagnostics.length() < limit {
    if errors.pop_front() is Some(error) {
      limited_diagnostics.push(error)
      continue
    }
    if warnings.pop_front() is Some(warning) {
      limited_diagnostics.push(warning)
      continue
    }
  }
  let diagnostic_texts = []
  for diagnostic in limited_diagnostics {
    let metadata = StringBuilder::new()
    let error_code_text = diagnostic.error_code.to_string().pad_start(4, '0')
    match diagnostic.level {
      Error => metadata.write_string("error[\{error_code_text}]")
      Warning => metadata.write_string("warning[\{error_code_text}]")
    }
    let path = diagnostic.loc.path.trim_space().to_string()
    if path != "" {
      metadata.write_string(": \{diagnostic.loc.path}")
    }
    let message_lines = ["\{metadata}: \{diagnostic.message}"]
    if path == "" {
      diagnostic_texts.push(message_lines.join("\n"))
      continue
    }
    let lines = match cache.get(path) {
      Some(content) => content
      None => {
        let content = @fs.read_file(path) catch {
          error => {
            message_lines.push("  (error reading file: \{error})")
            diagnostic_texts.push(message_lines.join("\n"))
            continue
          }
        }
        let lines = content.split("\n").collect()
        cache[path] = lines
        lines
      }
    }
    if diagnostic.loc.start.line != diagnostic.loc.end.line {
      let number_width = @cmp.maximum(
        diagnostic.loc.start.line.to_string().length(),
        diagnostic.loc.end.line.to_string().length(),
      )
      let start_line_number = diagnostic.loc.start.line
        .to_string()
        .pad_start(number_width, ' ')
      let end_line_number = diagnostic.loc.end.line
        .to_string()
        .pad_start(number_width, ' ')
      let start_line_text = lines[diagnostic.loc.start.line - 1]
      message_lines.push(" \{start_line_number} │ \{start_line_text}")
      let number_padding = " ".repeat(number_width)
      let text_padding = " ".repeat(diagnostic.loc.start.col - 1)
      let start_line_carets = "^".repeat(
        start_line_text.length() - diagnostic.loc.start.col + 1,
      )
      message_lines.push(
        " \{number_padding} │ \{text_padding}\{start_line_carets}",
      )
      if diagnostic.loc.start.line + 1 < diagnostic.loc.end.line {
        message_lines.push(" \{number_padding} ┆")
      }
      let end_line_text = lines[diagnostic.loc.end.line - 1]
      message_lines.push(" \{end_line_number} │ \{end_line_text}")
      let end_line_carets = "^".repeat(diagnostic.loc.end.col - 1)
      message_lines.push(" \{number_padding} │ \{end_line_carets}")
    } else {
      let line_number = diagnostic.loc.start.line.to_string()
      let line_text = lines[diagnostic.loc.start.line - 1]
      message_lines.push(" \{line_number} │ \{line_text}")
      let number_width = line_number.length()
      let number_padding = " ".repeat(number_width)
      let caret_text = "^".repeat(
        diagnostic.loc.end.col - diagnostic.loc.start.col,
      )
      let text_padding = " ".repeat(diagnostic.loc.start.col - 1)
      message_lines.push(" \{number_padding} │ \{text_padding}\{caret_text}")
    }
    diagnostic_texts.push(message_lines.join("\n"))
  }
  let truncation_messages = []
  if errors.length() > 0 {
    truncation_messages.push("\{errors.length()} more error(s)")
  }
  if warnings.length() > 0 {
    truncation_messages.push("\{warnings.length()} more warning(s)")
  }
  if truncation_messages.length() > 0 {
    let truncation_message = StringBuilder::new()
    for i, message in truncation_messages {
      if i < truncation_messages.length() - 2 {
        truncation_message.write_string("\{message}, ")
      } else if i == truncation_messages.length() - 2 {
        truncation_message.write_string("\{message} and ")
      } else {
        truncation_message.write_string(message)
      }
    }
    diagnostic_texts.push(
      "There are \{truncation_message} not shown due to diagnostic limit.",
    )
  }
  return diagnostic_texts.join("\n\n")
}

///|
fn create_submit_moonbit_segment_tool(
  moon : @moon.Module,
  segment : @moon.SegmentView,
  result : Ref[String?],
) -> @tool.Tool {
  @tool.tool(
    name="submit_moonbit_segment",
    description="Submit a fixed MoonBit code segment for verification",
    parameters={
      "properties": {
        "segment": {
          "description": "The fixed MoonBit code segment",
          "type": "string",
        },
      },
      "required": ["segment"],
      "type": "object",
    },
    (args, _) => {
      guard args is { "segment": patched, .. } else {
        return @tool.error("Missing 'segment' argument")
      }
      let patched : String = @json.from_json(patched) catch {
        error =>
          return @tool.error("Invalid 'segment' argument: \{error}", error~)
      }
      let diagnostics = moon.check_patch(segment, patched) catch {
        error => return @tool.error("Failed to check patch: \{error}", error~)
      }
      guard diagnostics is [diagnostic, ..] else {
        result.val = Some(patched)
        @tool.ok(
          "Segment verification successful! The code compiles without errors.",
        )
      }
      let overlay = {}
      overlay[diagnostic.loc.path] = patched
      let rendered_diagnostics = render_diagnostics(
        diagnostics,
        limit=10,
        overlay~,
      )
      return @tool.error(
        "Segment verification failed with errors:\n\{rendered_diagnostics}",
      )
    },
  )
}

///|
async fn process_segment(
  model~ : @model.Model,
  cwd~ : String,
  moon~ : @moon.Module,
  segment~ : @moon.SegmentView,
  description~ : String,
) -> String? {
  let result = Ref::new(None)
  let submit_tool = create_submit_moonbit_segment_tool(moon, segment, result)
  let subagent = @agent.new(model, cwd~)
  subagent.add_tool(submit_tool)
  subagent.add_message(
    @openai.system_message(
      content=(
        #|You are a highly skilled software developer with extensive knowledge in many programming languages, frameworks, design patterns, and best practices.
        #|In particular, you are an expert in the MoonBit programming language and you are primarily responsible for writing and improving MoonBit code.
        #|
        #|====
        #|
        #|CAPABILITIES
        #|
        #|- You can read and analyze MoonBit code and can write clean, efficient, and well-documented code.
        #|- You can debug complex issues and provide detailed explanations, offering architectural insights and design patterns.
        #|- You have access to the `submit_moonbit_segment` tool to submit and verify your fixed code segments.
        #|
        #|====
        #|
        #|RULES
        #|
        #|- Always read and understand the provided code segment before making changes.
        #|- When fixing code, ensure that your changes are minimal but effective, addressing all the reported issues.
        #|- Always use the `submit_moonbit_segment` tool to verify that your fix compiles without errors.
        #|- Provide complete, valid MoonBit code in your submissions - do not use placeholders or incomplete code.
        #|- Focus on fixing the specific issues mentioned in the diagnostics while maintaining code quality and best practices.
        #|- If the first attempt fails, analyze the error messages and refine your approach.
        #|
        #|====
        #|
        #|WORKFLOW
        #|
        #|1. Analyze the provided MoonBit code segment and understand the reported issues.
        #|2. Identify the root cause of each diagnostic/warning/error.
        #|3. Create a fixed version of the code segment that addresses all issues.
        #|4. Use the `submit_moonbit_segment` tool to verify your solution compiles correctly.
        #|5. If verification fails, analyze the error output and refine your fix until successful.
        #|
        #|Your goal is to provide a corrected MoonBit code segment that compiles without errors and addresses all the reported issues.
      ),
    ),
  )
  let user_message = StringBuilder::new()
  user_message.write_string(
    (
      $|Please fix the following MoonBit snippet with the following problem(s):
      $|
      $|**Problem Description:**
      $|\{description}
      $|
      $|**Original Segment:**
      $|```moonbit
      $|\{segment.content()}
      $|```
      $|
    ),
  )
  if !segment.diagnostics().is_empty() {
    user_message.write_string(
      (
        $|**Errors:**
        $|\{render_diagnostics(segment.diagnostics(), limit=10)}
        $|
      ),
    )
  }
  user_message.write_string(
    (
      #|Please provide a corrected version of this snippet addressing all concerns above.
      #|Use the <submit_moonbit_segment/> tool to submit and verify your solution.
    ),
  )
  subagent.add_message(@openai.user_message(content=user_message.to_string()))
  subagent.start()
  result.val
}

///|
pub let fix_moonbit_warnings : @tool.Tool = @tool.tool(
  name="fix_moonbit_warnings",
  description="Fix all MoonBit warnings/errors in the given project directory by applying a batch suggestion to all relevant MoonBit top-level constructs.",
  parameters={
    "properties": {
      "description": {
        "description": "A description of the changes to be made to fix the warnings/errors.",
        "type": "string",
      },
      "project_path": {
        "description": "The path to the project directory containing the moon.mod.json file.",
        "type": "string",
      },
    },
    "required": ["description", "project_path"],
  },
  (args, ctx : @tool.Context) => {
    guard args
      is {
        "description": String(description),
        "project_path": String(project_path),
        ..
      } else {
      return @tool.error("Missing 'description' or 'project_path' argument")
    }
    let cwd = ctx.cwd
    let project_path : String = if @path.is_absolute(project_path) {
      project_path
    } else {
      @path.join(cwd, project_path)
    }
    let moon = @moon.Module::load(project_path) catch {
      error => return @tool.error("Failed to load module: \{error}", error~)
    }
    let files = moon.files().collect()
    @async.with_timeout(
      120_000 * 4,
      () => moon.check(),
      error=Failure("Timeout after 4 minutes"),
    ) catch {
      error => return @tool.error("Failed to check module: \{error}", error~)
    }
    let mut files_updated = 0
    let mut segments_updated = 0
    @async.with_timeout_opt(60_000 * 10 * 8, () => @async.with_task_group(group => {
      for file in files {
        for segment in file.segments() {
          group.spawn_bg(() => {
            let updated = if @async.with_timeout_opt(120_000 * 4, () => process_segment(
                model=ctx.model,
                cwd=ctx.cwd,
                moon~,
                segment~,
                description~,
              ))
              is Some(updated) {
              updated
            } else {
              fail("Timeout after 4 minutes")
            }
            if updated is Some(updated) {
              segment.replace(updated)
              segments_updated += 1
            }
          }) catch {
            error =>
              println(
                "Warning: Failed to process segment in file \{file.path()}: \{error}",
              )
          }
        }
        files_updated += 1
      }
      @tool.ok(
        "Processed \{files_updated} files and updated \{segments_updated} segments.",
      )
    })).or_error(Failure("Takes too long processing all the segments")) catch {
      error => return @tool.error("Failed to process files: \{error}", error~)
    }
  },
)
