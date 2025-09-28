///|
priv suberror TimeoutError {
  TimeoutError(command~ : String, arguments~ : Array[String], timeout~ : Int)
} derive(ToJson, Show)

///|
struct Context {
  rand : @random.Rand
  cwd : String
}

///|
pub fn context(rand~ : @random.Rand, cwd~ : String) -> Context {
  Context::{ rand, cwd }
}

///|
/// Command execution result structure for structured JSON output
pub(all) struct CommandResult {
  command : String
  arguments : Array[String]
  exit_code : Int
  output : String
  truncated : Bool
  total_lines : Int
  timeout_ms : Int
  output_file : String?
} derive(ToJson, FromJson)

///|
pub let execute_command : @tool.Tool[Context] = @tool.tool(
  description="Execute a shell command",
  name="execute_command",
  parameters={
    "type": "object",
    "properties": {
      "command": {
        "type": "string",
        "description": "The shell command to execute",
      },
      "arguments": {
        "type": "array",
        "items": { "type": "string" },
        "description": "The arguments to pass to the command",
        "default": [],
      },
      "timeout": {
        "type": "number",
        "description": "The timeout in milliseconds for the command to execute",
        "default": 1000,
      },
      "max_output_lines": {
        "type": "number",
        "description": "The maximum number of output lines to return directly. If the output exceeds this number, it will be truncated and saved to a file.",
        "default": 100,
      },
    },
    "required": ["command", "arguments", "timeout"],
  },
  (args, ctx) => {
    let id = @uuid.v4(rand=ctx.rand)
    guard args
      is {
        "command": String(command),
        "arguments": arguments,
        "timeout": Number(timeout, ..),
        ..
      } else {
      return @tool.error(
        "Error: 'command', 'arguments' and 'timeout' parameters are required",
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
    let arguments : Array[String] = @json.from_json(arguments) catch {
      error => return @tool.error("Error parsing 'arguments': \{error}")
    }
    let timeout = timeout.to_int()
    try {
      let result = @async.with_timeout_opt(timeout, () => {
        let output = StringBuilder::new()
        let arguments_view = arguments.map(arg => arg.view())
        let status = @spawn.spawn(command, arguments_view, output~, cwd=ctx.cwd)
        let output_text = output.to_string()
        let lines = output_text.split("\n").collect()
        let (final_output, truncated, output_file) = if lines.length() >=
          max_output_lines {
          let relative_path = ".moonagent"
            |> @path.join("processes")
            |> @path.join("\{id}")
            |> @path.join("output.txt")
          let absolute_path = ctx.cwd |> @path.join(relative_path)
          @fs.make_directory(@path.dirname(absolute_path), recursive=true) catch {
            error =>
              return @tool.error(
                "Error creating directory for output file: \{error}",
                error~,
              )
          }
          @fs.write_to_file(absolute_path, output_text) catch {
            error =>
              return @tool.error(
                "Error writing output to file: \{error}",
                error~,
              )
          }
          let truncated_output = lines[:max_output_lines].join("\n")
          (truncated_output, true, Some(relative_path))
        } else {
          (output_text, false, None)
        }
        let result = CommandResult::{
          command,
          arguments,
          exit_code: status,
          output: final_output,
          truncated,
          total_lines: lines.length(),
          timeout_ms: timeout,
          output_file,
        }
        return @tool.ok(result.to_json())
      })
      match result {
        Some(result) => result
        None => {
          let error = TimeoutError(command~, arguments~, timeout~)
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
    let args_joined = cmd_result.arguments.join(" ")
    formatted.push("Command: \{cmd_result.command} \{args_joined}")
    formatted.push("Exit code: \{cmd_result.exit_code}")
    if cmd_result.truncated {
      let newline_split = cmd_result.output.split("\n")
      let output_lines_count = newline_split.collect().length()
      formatted.push(
        "Output: (first \{output_lines_count} of \{cmd_result.total_lines} lines)",
      )
      formatted.push(cmd_result.output)
      match cmd_result.output_file {
        Some(file_path) =>
          formatted.push(
            "... (truncated, use <read_file> tool to read full output at \{file_path}) ...",
          )
        None => ()
      }
    } else {
      formatted.push("Output:")
      formatted.push(cmd_result.output)
    }
    formatted.join("\n")
  },
)
