///|
priv suberror TimeoutError {
  TimeoutError(command~ : String, timeout~ : Int)
} derive(ToJson, Show)

///|
pub let execute_command : @tool.Tool[@job.Manager] = @tool.tool(
  description="Execute an shell command with arguments and capture its output.",
  name="execute_command",
  parameters={
    "type": "object",
    "properties": {
      "command": {
        "type": "string",
        "description": "The shell command to execute",
      },
      "timeout": {
        "type": "number",
        "description": "The timeout in milliseconds for the shell command to execute. This field is required if the command is executed in foreground (background=false).",
        "default": 1000,
      },
      "max_output_lines": {
        "type": "number",
        "description": "The maximum number of output lines to return directly. If the output exceeds this number, it will be truncated and saved to a file.",
        "default": 100,
      },
      "background": {
        "type": "boolean",
        "description": "Whether to run the command in the background (non-blocking). If true, the tool will return immediately after starting the command.",
        "default": false,
      },
    },
    "required": ["command"],
  },
  (args, ctx) => {
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
        @tool.ok(
          "Command: \{command}\nStarted in background with Job ID: \{job.id}",
        )
      } else {
        guard timeout is Some(timeout) else {
          return @tool.error(
            "'timeout' parameter is required when 'background' is false or not set, i.e. running in foreground",
          )
        }
        let timeout = timeout.to_int()
        let result = @async.with_timeout_opt(timeout, () => {
          let output = StringBuilder::new()
          let status = @spawn.spawn(
            "sh",
            ["-c", command],
            stdout=output,
            stderr=output,
            cwd=working_directory,
          )
          let output = output.to_string()
          let lines = output.split("\n").collect()
          let (output, truncated) = if lines.length() >= max_output_lines {
            let truncated_output = lines[:max_output_lines].join("\n")
            (truncated_output, true)
          } else {
            (output, false)
          }
          let formatted = []
          formatted.push("Command: \{command}")
          formatted.push("Exit code: \{status}")
          if truncated {
            let newline_split = output.split("\n")
            let output_lines_count = newline_split.collect().length()
            formatted.push(
              "Output: (first \{output_lines_count} of \{lines.length()} lines)",
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
          return @tool.ok(formatted.join("\n"))
        })
        match result {
          Some(result) => result
          None => {
            let error = TimeoutError(command~, timeout~)
            @tool.error("Timeout when executing command", error~)
          }
        }
      }
    } catch {
      error => @tool.error("Error executing command: \{error}", error~)
    }
  },
)
