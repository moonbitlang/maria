///|
pub suberror TimeoutError {
  TimeoutError(command~ : String, arguments~ : Array[String], timeout~ : Int)
} derive(ToJson, Show)

///|
pub let execute_command : @tool.Tool[String] = @tool.tool(
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
  (args, cwd) => {
    let id = @uuid.v4()
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
        let arguments = arguments.map(arg => arg.view())
        let status = @spawn.spawn(command, arguments, output~, cwd~)
        let output = output.to_string()
        let lines = output.split("\n").collect()
        if lines.length() >= max_output_lines {
          let relative_path = ".moonagent"
            |> @path.join("processes")
            |> @path.join("\{id}")
            |> @path.join("output.txt")
          let absolute_path = cwd |> @path.join(relative_path)
          @fs.make_directory(@path.dirname(absolute_path), recursive=true) catch {
            error =>
              return @tool.error(
                "Error creating directory for output file: \{error}",
                error~,
              )
          }
          @fs.write_to_file(absolute_path, output) catch {
            error =>
              return @tool.error(
                "Error writing output to file: \{error}",
                error~,
              )
          }
          let output = lines[:max_output_lines].join("\n")
          return @tool.ok(
            (
              $|Exit code: \{status}
              $|Output: (first \{max_output_lines} lines)
              $|\{output}
              $|... (truncated, total \{lines.length()} lines, use <read_file> tool to read full output at \{relative_path}) ...
            ),
          )
        } else {
          return @tool.ok(
            (
              $|Exit code: \{status}
              $|Output:
              $|\{output}
            ),
          )
        }
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
)
