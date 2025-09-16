///|
/// Discuss: MCP?
fn main {
  let mut timeout = 10
  let command = []
  loop @env.args()[1:] {
    [] => break
    ["--timeout"] => {
      println("Error: missing argument for --timeout")
      return
    }
    ["--timeout", to, .. rest] => {
      timeout = @strconv.parse_int(to) catch {
        error => {
          println("Error: invalid timeout value \{to}: \{error}")
          return
        }
      }
      continue rest
    }
    ["--", .. rest] => {
      for arg in rest {
        command.push(arg)
      }
      break
    }
    [arg, .. rest] => {
      command.push(arg)
      for arg in rest {
        command.push(arg)
      }
      break
    }
  }
  guard command is [command, .. arguments] else {
    println("Error: command should not be empty")
    return
  }
  let json : Json = {
    "command": command,
    "arguments": arguments,
    "timeout": timeout,
  }
  println(json.stringify(indent=2))
  let cwd = (@uv.cwd() |> @utf8.decode()) catch {
    error => {
      println("Error getting current working directory: \{error}")
      return
    }
  }
  let context = @tool.context(cwd~)
  @async.with_event_loop(_ => println(execute_command.call(json, context).output)) catch {
    error => println("Error executing command: \{error}")
  }
}
