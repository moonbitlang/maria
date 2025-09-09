///|
pub suberror TimeoutError {
  TimeoutError(command~ : String, arguments~ : Array[String], timeout~ : Int)
} derive(ToJson(style="flat"), Show)

///|
pub let execute_command : @tool.Tool = @tool.tool(
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
        "description": "The timeout in seconds for the command to execute",
        "default": 10,
      },
    },
    "required": ["command", "arguments", "timeout"],
  },
  (args, context) => {
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
    let arguments : Array[String] = @json.from_json(arguments) catch {
      error => return @tool.error("Error parsing 'arguments': \{error}")
    }
    let timeout = (timeout * 1000).to_int()
    try {
      let result = @async.with_timeout_opt(timeout, () => {
        let cmd = @encoding.encode(command, encoding=UTF8)
        let args = arguments.map(arg => @encoding.encode(arg, encoding=UTF8))
        let output = @pipe.pipe()
        let cwd = @encoding.encode(context.cwd, encoding=UTF8)
        let status = @process.run(
          cmd,
          args,
          stdout=output.1,
          stderr=output.1,
          cwd~,
        )
        let output = output.0.read_all() |> @encoding.decode(encoding=UTF8)
        return "Exit code: \{status}\nOutput:\n\{output}"
      })
      match result {
        Some(result) => @tool.ok(result)
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
