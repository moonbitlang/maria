///|
let submit_schema : @tool.JsonSchema = @tool.JsonSchema::from_json({
  "properties": {
    "segment": {
      "description": "The fixed MoonBit code segment",
      "type": "string",
    },
  },
  "required": ["segment"],
  "type": "object",
})

///|
fn submit_moonbit_segment_new(task : Task) -> @tool.Tool[String] {
  @tool.new(
    name="submit_moonbit_segment",
    description="Submit a fixed MoonBit code segment for verification",
    schema=submit_schema,
    @tool.ToolFn(async fn(args) -> @tool.ToolResult[String] noraise {
      let { moon, segment, result } = task
      guard args is { "segment": patched, .. } else {
        return @tool.error("Missing 'segment' argument")
      }
      let patched : String = @json.from_json(patched) catch {
        error =>
          return @tool.error("Invalid 'segment' argument: \{error}", error~)
      }
      let diagnostics = moon.check_patch_replace(segment, patched) catch {
        error => return @tool.error("Failed to check patch: \{error}", error~)
      }
      guard diagnostics is Diagnostics([diagnostic, ..]) else {
        result.val = Some(patched)
        @tool.ok(
          "The submitted code segment has been verified to compile without errors.",
        )
      }
      let overlay = {}
      overlay[diagnostic.loc.path] = segment.replace(patched)
      let rendered_diagnostics = diagnostics.render(
        context=1,
        limit=10,
        overlay~,
      )
      @tool.ok(
        "The submitted code segment has the following issues:\n\n" +
        "\{rendered_diagnostics}\n\n" +
        "Please fix these issues and resubmit the corrected code segment.",
      )
    }),
  )
}

///|
priv struct Task {
  moon : @moon.Module
  segment : @moon.SegmentView
  result : Ref[String?]
}

///|
async fn process_segment(
  model~ : @model.Model,
  cwd~ : String,
  moon~ : @moon.Module,
  segment~ : @moon.SegmentView,
  description~ : String,
  logger~ : @pino.Logger,
) -> String? {
  let result = Ref::new(None)
  let user_message = StringBuilder::new()
  user_message.write_string(
    (
      $|Please fix the following MoonBit snippet with the following problem(s):
      $|
      $|**Problem Description:**
      $|
      $|\{description}
      $|
      $|**Original Segment:**
      $|
      $|```moonbit
      $|\{segment.content()}
      $|```
      $|
    ),
  )
  if segment.diagnostics().length() != 0 {
    user_message.write_string(
      (
        $|**Errors:**
        $|\{segment.diagnostics().render(context=1, limit=10)}
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
  let system_message =
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
  let subagent = @agent.new(
    model,
    cwd~,
    logger~,
    system_message~,
    user_message=user_message.to_string(),
  )
  subagent.add_tool(submit_moonbit_segment_new(Task::{ moon, segment, result }))
  subagent.start()
  result.val
}

///|
let schema : @tool.JsonSchema = @tool.JsonSchema::from_json({
  "type": "object",
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
})

///|
priv struct Stat {
  mut files_updated : Int
  mut segments_updated : Int
}

///|
async fn process_file(
  agent~ : @agent.Agent,
  moon~ : @moon.Module,
  file~ : @moon.File,
  sem~ : @semaphore.Semaphore,
  description~ : String,
  stat~ : Stat,
) -> Unit {
  let segments_updates : Array[(@moon.SegmentView, Result[String?, Error])] = []
  @async.with_task_group(group => for segment in file.segments() {
    let warnings = segment.diagnostics().0.filter(d => d.level is Warning)
    if warnings.is_empty() {
      continue
    }
    sem.acquire()
    group.spawn_bg(() => {
      defer sem.release()
      segments_updates.push(
        (
          segment,
          try? @async.with_timeout(120_000 * 4, () => process_segment(
            model=agent.model,
            cwd=agent.cwd,
            moon~,
            segment~,
            description~,
            logger=agent.logger.child({
              "tool": { "name": "fix_moonbit_warnings", "id": agent.uuid.v4() },
            }),
          )),
        ),
      )
    })
  })
  stat.files_updated += 1
  for su in segments_updates {
    let (segment, update) = su
    guard update is Ok(patched) else { continue }
    if patched is Some(patched) {
      file.write(segment.replace(patched))
      stat.segments_updated += 1
    }
  }
}

///|
pub fn new(agent : @agent.Agent) -> @tool.Tool[String] {
  @tool.new(
    name="fix_moonbit_warnings",
    description="Fix all MoonBit warnings/errors in the given project directory by applying a batch suggestion to all relevant MoonBit top-level constructs.",
    schema~,
    @tool.ToolFn(async fn(args : Json) -> @tool.ToolResult[String] noraise {
      guard args
        is {
          "description": String(description),
          "project_path": String(project_path),
          ..
        } else {
        return @tool.error("Missing 'description' or 'project_path' argument")
      }
      let cwd = agent.cwd
      let project_path : String = if @pathx.is_absolute(project_path) {
        project_path
      } else {
        @pathx.join(cwd, project_path)
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
      let stat = Stat::{ files_updated: 0, segments_updated: 0 }
      let sem = @semaphore.Semaphore::new(4)
      let mut timed_out = false
      @async.with_timeout(60_000 * 10 * 8, () => @async.with_task_group(group => for
        file in files {
        if file.path().has_suffix(".mbt.md") {
          // Currently it is not supported to fix MoonBit code embedded in
          // markdown files
          continue
        }
        group.spawn_bg(() => process_file(
          agent~,
          moon~,
          file~,
          sem~,
          description~,
          stat~,
        ))
      })) catch {
        @async.TimeoutError => timed_out = true
        error =>
          return @tool.error("Failed to process segments: \{error}", error~)
      }
      if timed_out {
        @tool.error(
          "Operation timed out after processing \{stat.files_updated} files and updating \{stat.segments_updated} segments.",
        )
      } else {
        @tool.ok(
          "Processed \{stat.files_updated} files and updated \{stat.segments_updated} segments.",
        )
      }
    }),
  )
}
