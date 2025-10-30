///|
priv suberror TimeoutError {
  TimeoutError(command~ : String, timeout~ : Int)
} derive(ToJson, Show)

///|
pub enum CommandResult {
  Foreground(
    command~ : String,
    status~ : Int,
    output~ : String,
    truncated~ : Bool,
    total_lines~ : Int,
    timeout~ : Int
  )
  Background(command~ : String, job_id~ : @job.Id)
} derive(@json.FromJson, ToJson)

///|
pub impl Show for CommandResult with output(
  self : CommandResult,
  logger : &Logger,
) -> Unit {
  match self {
    Foreground(command~, status~, output~, truncated~, total_lines~, ..) => {
      let formatted = []
      formatted.push("Command: \{command}")
      formatted.push("Exit code: \{status}")
      if truncated {
        let newline_split = output.split("\n")
        let output_lines_count = newline_split.collect().length()
        formatted.push(
          "Output: (first \{output_lines_count} of \{total_lines} lines)",
        )
        formatted.push(output)
        if truncated {
          formatted.push(
            "... (truncated, try using redirection to pipe output to a file) ...",
          )
        } else {
          ()
        }
      } else {
        formatted.push("Output:")
        formatted.push(output)
      }
      logger.write_string(formatted.join("\n"))
    }
    Background(command~, job_id~) =>
      logger.write_string(
        "Command: \{command}\nStarted in background with Job ID: \{job_id}",
      )
  }
}

///|
pub fn new(ctx : @job.Manager) -> @tool.Tool[CommandResult] {
  @tool.new(
    description="Execute an shell command with arguments and capture its output.",
    name="execute_command",
    schema~,
    @tool.ToolFn(async fn(args) -> @tool.ToolResult[CommandResult] noraise {
      guard args is { "command": String(command), .. } else {
        return @tool.error("Error: 'command' parameters is required")
      }
      let timeout = if args is { "timeout": timeout, .. } {
        guard timeout.as_number() is Some(timeout) else {
          return @tool.error("'timeout' must be a number")
        }
        if timeout <= 0 {
          return @tool.error("'timeout' must be a positive integer")
        }
        Some(timeout)
      } else {
        None
      }
      let max_output_lines = if args
        is { "max_output_lines": Number(max_output_lines, ..), .. } {
        if max_output_lines <= 0 {
          return @tool.error("'max_output_lines' must be a positive integer")
        }
        max_output_lines.to_int()
      } else {
        100
      }
      let working_directory = if args
        is { "working_directory": String(working_directory), .. } {
        if @path.is_absolute(working_directory) {
          working_directory
        } else {
          @path.join(ctx.cwd, working_directory)
        }
      } else {
        ctx.cwd
      }
      let background = if args is { "background": background, .. } {
        guard background.as_bool() is Some(background) else {
          return @tool.error("'background' must be a boolean")
        }
        background
      } else {
        false
      }
      try {
        if background {
          let job = ctx.spawn(name=command, command~)
          @tool.ok(CommandResult::Background(command~, job_id=job.id))
        } else {
          guard timeout is Some(timeout) else {
            return @tool.error(
              "'timeout' parameter is required when 'background' is false or not set, i.e. running in foreground",
            )
          }
          let timeout = timeout.to_int()
          let output = StringBuilder::new()
          let result = @async.with_timeout_opt(timeout, () => {
            let status = @spawn.spawn(
              "sh",
              ["-c", command],
              stdout=output,
              stderr=output,
              cwd=working_directory,
            )
            let output_text = output.to_string()
            let lines = output_text.split("\n").collect()
            let (final_output, truncated) = if lines.length() >=
              max_output_lines {
              let truncated_output = lines[:max_output_lines].join("\n")
              (truncated_output, true)
            } else {
              (output_text, false)
            }
            return @tool.ok(
              CommandResult::Foreground(
                command~,
                status~,
                output=final_output,
                truncated~,
                total_lines=lines.length(),
                timeout~,
              ),
            )
          })
          match result {
            Some(result) => result
            None => {
              let error = TimeoutError(command~, timeout~)
              let output = output.to_string()
              if output.is_blank() {
                @tool.error(
                  "Timeout when executing command \{command} after \{timeout} ms",
                  error~,
                )
              } else {
                @tool.error(
                  (
                    $|Timeout when executing command \{command} after \{timeout} ms with following output:
                    $|
                    $|```
                    $|\{output.to_string()}
                    $|```
                  ),
                  error~,
                )
              }
            }
          }
        }
      } catch {
        error => @tool.error("Error executing command: \{error}", error~)
      }
    }),
  )
}
