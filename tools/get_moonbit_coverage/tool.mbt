///|
priv struct Params {
  file : String?
  project_path : String
} derive(FromJson, ToJson)

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
priv struct CoverageResult {
  content : String
} derive(ToJson, FromJson)

///|
fn CoverageResult::to_string(self : CoverageResult) -> String {
  self.content
}

///|
async fn execute_get_moonbit_coverage(
  cwd : String,
  file : String?,
  project_path : String,
) -> CoverageResult {
  let resolved_project_path = if @path.is_absolute(project_path) {
    project_path
  } else {
    @path.join(cwd, project_path)
  }
  let moon = @moon.Module::load(resolved_project_path)
  match file {
    Some(file) => CoverageResult::{ content: moon.coverage.analyze(file~) }
    None => CoverageResult::{ content: moon.coverage.report(format=Summary) }
  }
}

///|
let json_schema : Json = {
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
}

///|
pub let get_moonbit_coverage : @tool.Tool[String] = @tool.tool(
  description="Get coverage information for a MoonBit source file or project. If a specific file is provided, this tool analyzes that file and returns line-by-line coverage data. If the file is not found, it returns the coverage summary for the entire project.",
  name="get_moonbit_coverage",
  parameters=json_schema,
  (args, cwd) => {
    let args : Params = @json.from_json(args) catch {
      error => return @tool.error("Invalid arguments: \{error}", error~)
    }
    try execute_get_moonbit_coverage(cwd, args.file, args.project_path) catch {
      error =>
        @tool.error("Failed to get coverage information: \{error}", error~)
    } noraise {
      x => @tool.ok(x.to_json())
    }
  },
  render=result => try
    (@json.from_json(result.output()) : CoverageResult)
  catch {
    error => return "Error: Unexpected output format: \{error}"
  } noraise {
    coverage_result => return coverage_result.to_string()
  },
)
