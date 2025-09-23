///|
fn generate_test_cases_with_initial_gas(
  file : String,
  initial_gas : Int,
) -> Unit {

}

///|
fn generate_test_cases() -> Unit {

}

///|
const FileSplitPattern = "(\\d+) uncovered line\\(s\\) in (.*):"

///|
let file_split_regex : @regexp.Regexp = try! @regexp.compile(FileSplitPattern)

///|
struct CoverageFile {
  path : String
  uncovered : Int
  mut content : String
  mut toplevels : Array[CoverageToplevel]
}

///|
struct Coverage {
  files : Map[String, CoverageFile]
}

///|
fn Coverage::parse(string : String) -> Coverage raise {
  let files = {}
  let mut string = string[:]
  let mut last_file : CoverageFile? = None
  while file_split_regex.match_(string) is Some(matched) {
    let uncovered = @strconv.parse_int(matched.get(0).unwrap())
    let path = matched.get(1).unwrap().to_string()
    let content = matched.before().to_string()
    if last_file is Some(file) {
      file.content = content
      file.toplevels = content
        .split("…")
        .collect()
        .map(_.to_string())
        .map(CoverageToplevel::parse)
    }
    let file = CoverageFile::{
      path,
      uncovered,
      content: matched.before().to_string(),
      toplevels: [],
    }
    files[path] = file
    last_file = Some(file)
    string = matched.after()
  } else {
    if last_file is Some(file) {
      file.content = string.to_string()
      file.toplevels = string
        .split("…")
        .collect()
        .map(_.to_string())
        .map(CoverageToplevel::parse)
    }
  }
  Coverage::{ files, }
}

///|
test "file_split_regex" {
  let subjects = [
    "63 uncovered line(s) in tool/fix_moonbit_warnings/tool.mbt:", "7 uncovered line(s) in tool/file/read_file.mbt:",
    "guard args is { \"path\": String(path), .. } else {",
  ]
  let groups = []
  for subject in subjects {
    let matches = file_split_regex.execute(subject)
    groups.push(matches.results())
  }
  @json.inspect(groups, content=[
    [
      ["63 uncovered line(s) in tool/fix_moonbit_warnings/tool.mbt:"],
      ["63"],
      ["tool/fix_moonbit_warnings/tool.mbt"],
    ],
    [
      ["7 uncovered line(s) in tool/file/read_file.mbt:"],
      ["7"],
      ["tool/file/read_file.mbt"],
    ],
    [],
  ])
}

///|
fn fill_generate_tests_template(
  system~ : String,
  excerpt~ : String,
  name~ : String,
  coverage~ : String,
  package_~ : String,
  interface~ : String?,
) -> String {
  let prompt =
    $|\{system}
    $|
    $|Here is the coverage-annotated excerpt that you need to work on:
    $|
    $|\{excerpt}
    $|
    $|Your task is to add more test code to trigger the **uncovered lines** in **this excerpt only**.
    $|To do so, you should return **ONE TO FIVE** MoonBit test block(s) surrounded by **A SINGLE** markdown code block with language `moonbit`.
    $|
    $|Also, please note that your output must only include the tests (i.e. the functions starting with the `test` keyword), without any analyses or annotations.
    $|In addition, each test block should only test **only** what is presented the excerpt, **not** any other functions in the file.
    $|Please note that each test you add **must** involve triggering at least a currently-uncovered line.
    $|
    $|Finally, since you will be writing **BLACK-BOX** tests, it is only possible to call **PUBLIC** APIs within your tests.
    $|That is, you are only allowed to call functions visible from the `.mbti` file of the current package.
    $|Otherwise, the compiler will complain that `The value identifier ... is unbound.`
    $|
    $|For your reference, below is the coverage-annotated original source file `\{name}`, from which originated the above excerpt:
    $|
    $|\{coverage}
  if interface is Some(interface) {
    return prompt +
      (
        $|
        $|Here is the `.mbti` of the current package `@\{package_}`:
        $|
        $|\{interface}
      )
  } else {
    return prompt
  }
}

///|
const FnNamePattern = "(?:(?:async\\s+)?fn|impl.*?with) +([\\w:&]+)[([]"

///|
let fn_name_regex : @regexp.Regexp = try! @regexp.compile(FnNamePattern)

///|
test "FnNamePattern" {
  let subjects = [
    "async fn foo_bar() -> Unit {", "fn foo_bar() -> Unit {", "impl Foo with foo(",
    "impl Foo for Bar with foo(", "impl[T] Foo for Bar[T] with foo(", "impl[T, U] Foo for Bar[T, U] with foo(",
    "guard args is { \"path\": String(path), .. } else {",
  ]
  let regex = @regexp.compile(FnNamePattern)
  let groups = []
  for subject in subjects {
    let matches = regex.execute(subject)
    groups.push(matches.results())
  }
  @json.inspect(groups, content=[
    [["async fn foo_bar("], ["foo_bar"]],
    [["fn foo_bar("], ["foo_bar"]],
    [["impl Foo with foo("], ["foo"]],
    [["impl Foo for Bar with foo("], ["foo"]],
    [["impl[T] Foo for Bar[T] with foo("], ["foo"]],
    [["impl[T, U] Foo for Bar[T, U] with foo("], ["foo"]],
    [],
  ])
}

///|
priv struct CoverageToplevel {
  fn_name : String?
  is_fully_covered : Bool
  content : String
}

///|
fn CoverageToplevel::parse(string : String) -> CoverageToplevel {
  let fn_name = fn_name_regex.execute(string).get(0).map(_.to_string())
  let is_fully_covered = !string.contains("UNCOVERED")
  CoverageToplevel::{ fn_name, is_fully_covered, content: string }
}

///|
fn extract_code(content : String) -> String? {
  content
  .split("```moonbit")
  .drop(1)
  .take(1)
  .peek()
  .bind(block => block
    .split("```")
    .take(1)
    .peek()
    .map(s => s.trim(" \r\n\t").to_string()))
}

///|
async fn generate_unverified_test_case(
  coverage~ : String,
  name~ : String,
  package_~ : String,
  excerpt~ : String,
  interface~ : String?,
  model~ : @model.Model,
) -> String? {
  let message = fill_generate_tests_template(
    system="You are an expert MoonBit developer and testing engineer.",
    excerpt~,
    name~,
    coverage~,
    package_~,
    interface~,
  )
  let response = @ai.chat(
    model~,
    @openai.chat_completion(model=model.name, messages=[
      @openai.user_message(content=message),
    ]),
  )
  let content = response.choices[0].message.content.unwrap_or("")
  extract_code(content)
}

///|
async fn generate_unverified_test_cases(
  model~ : @model.Model,
  file~ : String,
  moon~ : @moon.Module,
) -> Map[String, String] {
  let package_ = moon.locate_package(file)
  let coverage = Coverage::parse(moon.coverage.analyze(package_~))
  let interface = package_.interface()
  let test_cases = {}
  for pair in coverage.files.to_array() {
    let (_, file) = pair
    for toplevel in file.toplevels {
      if toplevel.is_fully_covered {
        continue
      }
      guard toplevel.fn_name is Some(fn_name) else { continue }
      let test_case = generate_unverified_test_case(
        model~,
        coverage=file.content,
        name=file.path,
        package_=package_.name(),
        excerpt=toplevel.content,
        interface~,
      )
      if test_case is Some(test_case) {
        test_cases[fn_name] = test_case
      }
    }
  }
  test_cases
}

///|
pub let add_moonbit_test : @tool.Tool[@agent.Agent] = @tool.tool(
  name="add_moonbit_test",
  description="Add moonbit test to the current project",
  parameters={
    "project_path": {
      "description": "The path to the MoonBit project (parent path of moon.mod.json), relative to the current working directory.",
      "type": "string",
    },
    "source_files": {
      "description": "A list of source files to add the test to, relative to the project path.",
      "type": "array",
      "items": { "type": "string" },
    },
    "required": ["project_path", "source_files"],
  },
  (args, agent) => @tool.error("Not implemented yet."),
)
