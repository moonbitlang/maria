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
      try {
        let cwd_path = @path.Path::parse(cwd)
        if cwd_path.is_absolute() {
          cwd
        } else {
          let os_cwd = @path.Path::parse(@os.cwd())
          let path_builder = @path.PathBuilder::from_path(os_cwd)
          for dir in cwd_path.directory() {
            path_builder.add_directory(dir)
          }
          path_builder.to_string()
        }
      } catch {
        _ => cwd
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
  @diagnostics.from_jsonl(output)
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
  @diagnostics.from_jsonl(output.to_string())
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
  @fs.with_temporary_directory("moonbit-moon-check-syntax-XXXXXXX", tmpdir => {
    let (dir_path, file_path) : (String, String) = try {
      let path = @path.Path::parse(path)
      if path.is_absolute() {
        (path.prefix() + path.directory()[:].join("/"), path.to_string())
      } else {
        let tmpdir_path = @path.Path::parse(tmpdir, kind=Directory)
        let path_builder = @path.PathBuilder::from_path(tmpdir_path)
        for dir in path.directory() {
          path_builder.add_directory(dir)
        }
        let dir_path = path_builder.to_string(kind=File)
        match path.file() {
          Some(file) => path_builder.set_basename(file.to_string())
          None => ()
        }
        (dir_path, path_builder.to_string())
      }
    } catch {
      _ => {
        let tmpdir_path = @path.Path::parse(tmpdir, kind=Directory)
        let path_builder = @path.PathBuilder::from_path(tmpdir_path)
        path_builder.set_basename(path)
        (tmpdir, path_builder.to_string())
      }
    }
    @fs.make_directory(dir_path, recursive=true, exists_ok=true)
    @fs.write_to_file(file_path, source)
    check_syntax_of_file(file_path)
  })
}
