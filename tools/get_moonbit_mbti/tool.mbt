///|
let schema : @tool.JsonSchema = @tool.JsonSchema::from_json({
  "type": "object",
  "properties": {
    "package": {
      "type": "string",
      "description": "The name of the package to analyze (e.g. 'moonbitlang/core/set`').",
    },
  },
  "required": ["package"],
})

///|
pub fn new(cwd : String) -> @tool.Tool[String] {
  @tool.new(
    name="get_moonbit_mbti",
    description="Get Moonbit MBTI",
    schema~,
    @tool.ToolFn(async fn(args) -> @tool.ToolResult[String] noraise {
      guard args is { "package": String(pkg_name), .. } else {
        @tool.error(
          "Error: 'package' argument is required and must be a string.",
        )
      }
      try {
        let moon = @moon.Module::load(cwd) catch { error => @errortrace.reraise(error) }
        let pkg_result = moon.find_package(pkg_name) catch { error => @errortrace.reraise(error) }
        guard pkg_result is Some(pkg) else {
          return @tool.error("Error: Package '\{pkg_name}' not found in module.")
        }
        let interface = pkg.interface() catch { error => @errortrace.reraise(error) }
        @tool.ok(interface)
      } catch {
        error => @tool.error("Error: \{error}", error~)
      }
    }),
  )
}
