///|
pub async fn clone(url : String, to~ : String) -> Unit raise {
  let status = @process.run("git", [
    "clone",
    @utf8.encode(url),
    @utf8.encode(to),
  ])
  if status != 0 {
    fail("git clone failed with status code \{status}")
  }
}

///|
pub async fn init_(path : String, output? : &Logger) -> Unit raise {
  let status = @spawn.spawn("git", ["init", path], output?)
  if status != 0 {
    fail("git init failed with status code \{status}")
  }
}

///|
pub async fn commit(
  message : @string.View,
  files : Array[@string.View],
  output? : &Logger,
  cwd? : @string.View,
) -> Unit {
  let buffer = StringBuilder::new()
  let status = @spawn.spawn("git", ["add", ..files], output=buffer, cwd?)
  guard status is 0 else {
    fail("git add failed with \{status}: \{buffer.to_string()}")
  }
  let status = @spawn.spawn(
    "git",
    ["commit", "-m", message],
    output=buffer,
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
pub async fn create_branch(branch_name~ : String, cwd? : String) -> String {
  let cwd = cwd.map(@utf8.encode(_))
  guard @process.run("git", ["branch", @utf8.encode(branch_name)], cwd?) is 0 else {
    fail("git branch creation failed")
  }
  return "Branch '\{branch_name}' created successfully"
}

///|
pub async fn generate_git_diff(
  original~ : String,
  modified~ : String,
) -> String raise {
  @async.with_task_group(group => @fs.with_temporary_directory(
    "maria-git-diff-XXXXXXX",
    tmpdir => {
      let original_path = @path.join(tmpdir, "original.txt")
      @fs.write_to_file(original_path, original)
      let modified_path = @path.join(tmpdir, "modified.txt")
      @fs.write_to_file(modified_path, modified)
      let buffer = @buffer.new()
      group.add_defer(() => @fs.remove(original_path))
      group.add_defer(() => @fs.remove(modified_path))
      let output = StringBuilder::new()
      @spawn.spawn(
        "git",
        [
          "diff", "--no-index", "--no-index", "--no-prefix", "--unified=3", original_path,
          modified_path,
        ],
        output~,
      )
      |> ignore()
      @utf8.decode(buffer.contents())
    },
  ))
}
