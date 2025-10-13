///|
priv suberror TimeoutError {
  TimeoutError(command~ : String, timeout~ : Int)
} derive(ToJson, Show)

///|
struct Context {
  cwd : String
}

///|
pub fn context(cwd~ : String) -> Context {
  Context::{ cwd, }
}

///|
/// Command execution result structure for structured JSON output
pub(all) struct CommandResult {
  command : String
  exit_code : Int
  output : String
  truncated : Bool
  total_lines : Int
  timeout_ms : Int
} derive(ToJson, FromJson)

///|
pub let execute_command : @tool.Tool[Context] = @tool.tool(
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
        "description": "The timeout in milliseconds for the shell command to execute",
        "default": 1000,
      },
      "max_output_lines": {
        "type": "number",
        "description": "The maximum number of output lines to return directly. If the output exceeds this number, it will be truncated and saved to a file.",
        "default": 100,
      },
    },
    "required": ["command", "timeout"],
  },
  (args, ctx) => {
    guard args
      is { "command": String(command), "timeout": Number(timeout, ..), .. } else {
      return @tool.error(
        "Error: 'command' and 'timeout' parameters are required",
      )
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
    let timeout = timeout.to_int()
    try {
      let result = @async.with_timeout_opt(timeout, () => {
        let output = StringBuilder::new()
        let status = @spawn.spawn(
          "sh",
          ["-c", command],
          output~,
          cwd=working_directory,
        )
        let output_text = output.to_string()
        let lines = output_text.split("\n").collect()
        let (final_output, truncated) = if lines.length() >= max_output_lines {
          let truncated_output = lines[:max_output_lines].join("\n")
          (truncated_output, true)
        } else {
          (output_text, false)
        }
        let result = CommandResult::{
          command,
          exit_code: status,
          output: final_output,
          truncated,
          total_lines: lines.length(),
          timeout_ms: timeout,
        }
        return @tool.ok(result.to_json())
      })
      match result {
        Some(result) => result
        None => {
          let error = TimeoutError(command~, timeout~)
          @tool.error("Timeout when executing command", error~)
        }
      }
    } catch {
      error => @tool.error("Error executing command: \{error}", error~)
    }
  },
  render=result => {
    let cmd_result : CommandResult = @json.from_json(result.output) catch {
      error => return "Error: Unexpected output format: \{error}"
    }
    let formatted = []
    formatted.push("Command: \{cmd_result.command}")
    formatted.push("Exit code: \{cmd_result.exit_code}")
    if cmd_result.truncated {
      let newline_split = cmd_result.output.split("\n")
      let output_lines_count = newline_split.collect().length()
      formatted.push(
        "Output: (first \{output_lines_count} of \{cmd_result.total_lines} lines)",
      )
      formatted.push(cmd_result.output)
      if cmd_result.truncated {
        formatted.push(
          "... (truncated, try using redirection to pipe output to a file) ...",
        )
      } else {
        ()
      }
    } else {
      formatted.push("Output:")
      formatted.push(cmd_result.output)
    }
    formatted.join("\n")
  },
)
