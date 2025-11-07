///|
async fn check(
  package_path? : StringView,
  patch_file? : StringView,
  target_dir? : StringView,
  cwd? : StringView,
) -> @diagnostics.Diagnostics {
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
  let result = @spawn.spawn("moon", arguments, cwd~)
  @diagnostics.from_jsonl(result.stdout + result.stderr)
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
) -> @diagnostics.Diagnostics {
  let result = @spawn.spawn(
    "moonc",
    [
      "compile", "-no-intermediate-file", "-stop-after-parsing", "-error-format",
      "json", path,
    ],
    cwd?,
  )
  @diagnostics.from_jsonl(result.stdout + result.stderr)
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
) -> @diagnostics.Diagnostics {
  @fsx.with_temporary_directory("moonbit-moon-check-syntax-XXXXXXX", tmpdir => {
    let file_path = @path.join(tmpdir, path)
    @fsx.make_directory(
      @path.dirname(file_path),
      recursive=true,
      exists_ok=true,
    )
    @fsx.write_to_file(file_path, source)
    check_syntax_of_file(file_path)
  })
}
