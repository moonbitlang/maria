///|
pub let get_moonbit_mbti : @tool.Tool[String] = @tool.tool(
  name="get_moonbit_mbti",
  description="Get Moonbit MBTI",
  parameters={
    "type": "object",
    "properties": {
      "package": {
        "type": "string",
        "description": "The name of the package to analyze (e.g. 'moonbitlang/core/set`').",
      },
    },
    "required": ["package"],
  },
  (args, cwd) => {
    guard args is { "package": String(pkg_name), .. } else {
      @tool.error("Error: 'package' argument is required and must be a string.")
    }
    let moon = @moon.Project::new(cwd) catch {
      error =>
        return @tool.error(
          "Error: Failed to load module at '\{cwd}': \{error}",
          error~,
        )
    }
    let pkg = moon.package_(pkg_name) catch {
      error =>
        return @tool.error(
          "Error: Failed to find package '\{pkg_name}': \{error}",
          error~,
        )
    }
    guard pkg is Some(pkg) else {
      @tool.error("Error: Package '\{pkg_name}' not found in module.")
    }
    let interface = pkg.interface() catch {
      error =>
        return @tool.error(
          "Error: Failed to get interface for package '\{pkg_name}': \{error}",
          error~,
        )
    }
    @tool.ok(interface.to_json())
  },
  render=result => {
    guard result.output() is String(result)
    result
  },
)
