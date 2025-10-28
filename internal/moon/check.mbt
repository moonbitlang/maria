///|
pub enum Level {
  Error
  Warning
} derive(Show, ToJson)

///|
impl @json.FromJson for Level with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Level raise @json.JsonDecodeError {
  match json {
    "error" => Level::Error
    "warning" => Level::Warning
    _ =>
      raise @json.JsonDecodeError((json_path, "Expected 'error' or 'warning'."))
  }
}

///|
pub struct Pos {
  col : Int
  line : Int
} derive(Show, ToJson)

///|
impl @json.FromJson for Pos with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Pos raise @json.JsonDecodeError {
  guard json is { "col": col, "line": line, .. } else {
    raise @json.JsonDecodeError(
      (json_path, "Expected object with 'col' and 'line'."),
    )
  }
  let col : Int = @json.from_json(col, path=json_path.add_key("col"))
  let line : Int = @json.from_json(line, path=json_path.add_key("line"))
  Pos::{ col, line }
}

///|
pub struct Loc {
  end : Pos
  path : String
  start : Pos
} derive(Show, ToJson)

///|
impl @json.FromJson for Loc with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Loc raise @json.JsonDecodeError {
  guard json is { "end": end, "path": path, "start": start, .. } else {
    raise @json.JsonDecodeError(
      (json_path, "Expected object with 'end', 'path' and 'start'."),
    )
  }
  let end : Pos = @json.from_json(end, path=json_path.add_key("end"))
  let path : String = @json.from_json(path, path=json_path.add_key("path"))
  let start : Pos = @json.from_json(start, path=json_path.add_key("start"))
  Loc::{ end, path, start }
}

///|
pub struct Diagnostic {
  error_code : Int
  level : Level
  loc : Loc
  message : String
} derive(Show, ToJson)

///|
pub impl @json.FromJson for Diagnostic with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Diagnostic raise @json.JsonDecodeError {
  guard json
    is {
      "error_code": error_code,
      "level": level,
      "loc": loc,
      "message": message,
      ..
    } else {
    raise @json.JsonDecodeError(
      (json_path, "Expected object with 'error_code'."),
    )
  }
  let error_code : Int = @json.from_json(
    error_code,
    path=json_path.add_key("error_code"),
  )
  let level : Level = @json.from_json(level, path=json_path.add_key("level"))
  let loc : Loc = @json.from_json(loc, path=json_path.add_key("loc"))
  let message : String = @json.from_json(
    message,
    path=json_path.add_key("message"),
  )
  Diagnostic::{ error_code, level, loc, message }
}

///|
async fn check(
  package_path? : StringView,
  patch_file? : StringView,
  target_dir? : StringView,
  cwd? : StringView,
) -> Array[Diagnostic] {
  let cwd : StringView = match cwd {
    None => @os.cwd()
    Some(cwd) =>
      if @path.is_absolute(cwd) {
        cwd
      } else {
        @path.join(@os.cwd(), cwd)
      }
  }
  let arguments : Array[StringView] = ["check", "--output-json"]
  if package_path is Some(package_path) {
    arguments.push("--package-path")
    arguments.push(package_path)
  }
  if patch_file is Some(patch_file) {
    arguments.push("--patch-file")
    arguments.push(patch_file)
  }
  if target_dir is Some(target_dir) {
    arguments.push("--target-dir")
    arguments.push(target_dir)
  }
  arguments.push("--directory")
  arguments.push(cwd)
  let output = StringBuilder::new()
  let _ = @spawn.spawn("moon", arguments, stdout=output, stderr=output, cwd~)
  let output = output.to_string()
  let diagnostics = []
  for line in output.split("\n") {
    try {
      let json = @json.parse(line.to_string())
      let diagnostic : Diagnostic = @json.from_json(json)
      diagnostics.push(diagnostic)
    } catch {
      _ => continue
    }
  }
  diagnostics
}

///|
/// Validates the syntax of a MoonBit source file by running the MoonBit
/// compiler in parse-only mode.
///
/// Parameters:
///
/// * `path` : The file path to the MoonBit source file to be checked.
/// * `cwd` : Optional working directory from which to run the compiler. If not
///   provided, uses the current working directory.
///
/// Returns an array of `Diagnostic` objects containing any syntax errors or
/// warnings found in the file.
pub async fn check_syntax_of_file(
  path : String,
  cwd? : StringView,
) -> Array[Diagnostic] {
  let output = StringBuilder::new()
  let _ = @spawn.spawn(
    "moonc",
    [
      "compile", "-no-intermediate-file", "-stop-after-parsing", "-error-format",
      "json", path,
    ],
    stdout=output,
    stderr=output,
    cwd?,
  )
  let output = output.to_string()
  let diagnostics = []
  for line in output.split("\n") {
    try {
      let json = @json.parse(line.to_string())
      let diagnostic : Diagnostic = @json.from_json(json)
      diagnostics.push(diagnostic)
    } catch {
      _ => continue
    }
  }
  diagnostics
}

///|
/// Validates the syntax of MoonBit source code provided as a string by creating
/// a temporary file and running syntax checking on it.
///
/// Parameters:
///
/// * `path` : Optional file path to use for error reporting. If not provided, a
///   default temporary file name will be used in diagnostic messages.
/// * `source` : The MoonBit source code to validate as a string.
///
/// Returns an array of `Diagnostic` objects containing any syntax errors or
/// warnings found in the source code.
pub async fn check_syntax_of_string(
  path? : String = "source.mbt",
  source : String,
) -> Array[Diagnostic] {
  @fs.with_temporary_directory("moonbit-moon-check-syntax-XXXXXXX", tmpdir => {
    let file_path = @path.join(tmpdir, path)
    @fs.write_to_file(file_path, source)
    check_syntax_of_file(file_path)
  })
}
