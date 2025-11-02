///|
async fn check(
  package_path? : StringView,
  patch_file? : StringView,
  target_dir? : StringView,
  cwd? : StringView,
) -> Array[@diagnostics.Diagnostic] {
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
      let diagnostic : @diagnostics.Diagnostic = @json.from_json(json)
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
) -> Array[@diagnostics.Diagnostic] {
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
      let diagnostic : @diagnostics.Diagnostic = @json.from_json(json)
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
) -> Array[@diagnostics.Diagnostic] {
  @fs.with_temporary_directory("moonbit-moon-check-syntax-XXXXXXX", tmpdir => {
    let file_path = @path.join(tmpdir, path)
    @fs.make_directory(@path.dirname(file_path), recursive=true, exists_ok=true)
    @fs.write_to_file(file_path, source)
    check_syntax_of_file(file_path)
  })
}
