///|
priv struct Params {
  file : String?
  project_path : String
} derive(@json.FromJson, ToJson)

///|
fn params(file? : String, project_path~ : String) -> Params {
  Params::{ file, project_path }
}

///|
test "params ToJson" {
  @json.inspect(params(file="src/main.mbt", project_path="."), content={
    "file": "src/main.mbt",
    "project_path": ".",
  })
}

///|
pub let get_moonbit_coverage : @tool.Tool[String] = @tool.tool(
  description="Get coverage information for a MoonBit source file or project. If a specific file is provided, this tool analyzes that file and returns line-by-line coverage data. If the file is not found, it returns the coverage summary for the entire project.",
  name="get_moonbit_coverage",
  parameters={
    "type": "object",
    "properties": {
      "file": {
        "type": "string",
        "description": "The path to the MoonBit source file to analyze. If not provided, the tool will return coverage information for the entire project.",
      },
      "project_path": {
        "type": "string",
        "description": "The path to the MoonBit project (parent path of moon.mod.json), relative to the current working directory.",
      },
    },
    "required": ["project_path"],
  },
  (args, cwd) => {
    let args : Params = @json.from_json(args) catch {
      error => return @tool.error("Invalid arguments: \{error}", error~)
    }
    let resolved_project_path = if @path.is_absolute(args.project_path) {
      args.project_path
    } else {
      @path.join(cwd, args.project_path)
    }
    let moon = @moon.Module::load(resolved_project_path) catch {
      error =>
        return @tool.error(
          "Failed to load MoonBit project at '\{resolved_project_path}': \{error}",
          error~,
        )
    }
    guard args.file is Some(file) else {
      @tool.ok(moon.coverage.report(format=Summary)) catch {
        error =>
          @tool.error(
            "Failed to get coverage summary for project at '\{resolved_project_path}': \{error}",
            error~,
          )
      }
    }
    @tool.ok(moon.coverage.analyze(file~)) catch {
      error =>
        @tool.error(
          "Failed to analyze coverage for file '\{file}': \{error}",
          error~,
        )
    }
  },
)
