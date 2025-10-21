///|
pub async fn clone(url : String, to~ : StringView, cwd? : StringView) -> Unit {
  let arguments : Array[StringView] = ["clone", url, to]
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
  let buffer = StringBuilder::new()
  let status = @spawn.spawn(
    "git",
    ["add", ..files],
    stdout=buffer,
    stderr=buffer,
    cwd?,
  )
  guard status is 0 else {
    fail("git add failed with \{status}: \{buffer.to_string()}")
  }
  let status = @spawn.spawn(
    "git",
    ["commit", "-m", message],
    stdout=buffer,
    stderr=buffer,
    cwd?,
  )
  guard status is 0 else {
    fail("git commit failed with \{status}: \{buffer.to_string()}")
  }
  if output is Some(output) {
    output.write_string(buffer.to_string())
  }
}

///|
pub async fn generate_git_diff(
  original~ : String,
  modified~ : String,
) -> String {
  @fs.with_temporary_directory("maria-git-diff-XXXXXXX", tmpdir => {
    let original_path = @path.join(tmpdir, "original.txt")
    @fs.write_to_file(original_path, original)
    let modified_path = @path.join(tmpdir, "modified.txt")
    @fs.write_to_file(modified_path, modified)
    let output = StringBuilder::new()
    @spawn.spawn(
      "git",
      [
        "diff", "--no-index", "--no-index", "--no-prefix", "--unified=3", original_path,
        modified_path,
      ],
      stdout=output,
      stderr=output,
    )
    |> ignore()
    output.to_string()
  })
}
