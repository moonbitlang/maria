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
    // concat `/` make path library parsing as directory
    let path = @path.Path::parse(tmpdir + "/")
    let path_builder = @path.PathBuilder::from_path(path)
    path_builder.set_basename("original")
    let original_path = path_builder.to_string()
    path_builder.set_basename("modified")
    let modified_path = path_builder.to_string()

    // TODO: Here we can write two files concurrently
    @fs.write_to_file(original_path, original)
    @fs.write_to_file(modified_path, modified)
    let output = StringBuilder::new()
    // TODO: add environment variable support
    @spawn.spawn(
      "git",
      [
        "diff", "--no-ext-diff", "--no-index", "--no-prefix", "--unified=3", "original",
        "modified",
      ],
      stdout=output,
      stderr=output,
      cwd=tmpdir,
    )
    |> ignore()
    output.to_string()
  })
}
