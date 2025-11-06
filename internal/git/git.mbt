///|
pub async fn clone(
  url : String,
  to~ : StringView,
  cwd? : StringView,
  depth? : Int,
) -> Unit {
  let arguments : Array[StringView] = ["clone"]
  if depth is Some(d) {
    guard d > 0 else { fail("depth must be a positive integer") }
    arguments.push("--depth")
    arguments.push(d.to_string())
  }
  arguments.push(url)
  arguments.push(to)
  let status = @spawn.spawn("git", arguments, cwd?)
  if status != 0 {
    fail("git clone failed with status code \{status}")
  }
}

///|
pub async fn init_(path : String) -> Unit {
  let status = @spawn.spawn("git", ["init", path])
  if status != 0 {
    fail("git init failed with status code \{status}")
  }
}

///|
pub async fn commit(
  message : StringView,
  files : Array[StringView],
  output? : &Logger,
  cwd? : StringView,
) -> Unit {
  let stdout = StringBuilder::new()
  let stderr = StringBuilder::new()
  let status = @spawn.spawn("git", ["add", ..files], stdout~, stderr~, cwd?)
  guard status is 0 else {
    fail("git add failed with \{status}: \{stdout.to_string()}")
  }
  stdout.reset()
  stderr.reset()
  let status = @spawn.spawn(
    "git",
    ["commit", "-m", message],
    stdout~,
    stderr~,
    cwd?,
  )
  guard status is 0 else {
    fail("git commit failed with \{status}: \{stdout.to_string()}")
  }
  if output is Some(output) {
    output.write_string(stdout.to_string())
  }
}

///|
pub async fn generate_git_diff(
  original~ : String,
  modified~ : String,
  line_number? : Bool = false,
) -> String {
  @fs.with_temporary_directory("maria-git-diff-XXXXXXX", tmpdir => {
    let original_path = @path.join(tmpdir, "original")
    @fs.write_to_file(original_path, original)
    let modified_path = @path.join(tmpdir, "modified")
    @fs.write_to_file(modified_path, modified)
    let stdout = StringBuilder::new()
    // TODO: add environment variable support
    @spawn.spawn(
      "git",
      [
        "diff", "--no-ext-diff", "--no-index", "--no-prefix", "--unified=3", "original",
        "modified",
      ],
      stdout~,
      cwd=tmpdir,
    )
    |> ignore()
    let output = stdout.to_string().trim_space().to_string()
    if line_number {
      add_line_number_to_diff(output)
    } else {
      output
    }
  })
}
