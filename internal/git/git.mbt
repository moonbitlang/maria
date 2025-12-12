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
  @spawn.spawn("git", arguments, cwd?).check()
}

///|
pub async fn init_(path : String) -> Unit {
  @spawn.spawn("git", ["init", path]).check()
}

///|
pub async fn commit(
  message : StringView,
  files : Array[StringView],
  cwd? : StringView,
) -> Unit {
  @spawn.spawn("git", ["add", ..files], cwd?).check()
  @spawn.spawn("git", ["commit", "-m", message], cwd?).check()
}

///|
pub async fn generate_git_diff(
  original~ : String,
  modified~ : String,
  line_number? : Bool = false,
) -> String {
  @fsx.with_temporary_directory("maria-git-diff-XXXXXXX", tmpdir => {
    let original_path = @pathx.join(tmpdir, "original")
    @fsx.write_to_file(original_path, original)
    let modified_path = @pathx.join(tmpdir, "modified")
    @fsx.write_to_file(modified_path, modified)
    // TODO: add environment variable support
    let process = @spawn.spawn(
      "git",
      [
        "diff", "--no-ext-diff", "--no-index", "--no-prefix", "--unified=3", "original",
        "modified",
      ],
      cwd=tmpdir,
    )
    let output = process.stdout.trim_space().to_string()
    if line_number {
      add_line_number_to_diff(output)
    } else {
      output
    }
  })
}
