///|
async test "add_worktree" (t : @test.T) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    let _ = mock.add_file("file.txt", content="Hello, Moonbit!")
    @git.commit("Initial commit", ["file.txt"], cwd=mock.cwd.path())
    @git.add_worktree("worktree", cwd=mock.cwd.path())
    mock.group.add_defer(() => @git.remove_worktree(
      "worktree",
      force=true,
      cwd=mock.cwd.path(),
    ))
    let cwd = mock.cwd.path()
    let path = @path.Path::parse(cwd + "/")
    let path_builder = @path.PathBuilder::from_path(path)
    path_builder.add_directory("worktree")
    path_builder.set_file(base="file", extension="txt")
    let content = @fs.read_file(path_builder.to_string())
    @json.inspect(content, content="Hello, Moonbit!")
  })
}

///|
async test "add_worktree/new-branch" (t : @test.T) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    let _ = mock.add_file("file.txt", content="Hello, Moonbit!")
    @git.commit("Initial commit", ["file.txt"], cwd=mock.cwd.path())
    @git.add_worktree("worktree", new_branch="new-branch", cwd=mock.cwd.path())
    mock.group.add_defer(() => @git.remove_worktree(
      "worktree",
      force=true,
      cwd=mock.cwd.path(),
    ))
    let cwd = mock.cwd.path()
    let path = @path.Path::parse(cwd + "/")
    let path_builder = @path.PathBuilder::from_path(path)
    path_builder.add_directory("worktree")
    path_builder.set_file(base="file", extension="txt")
    let content = @fs.read_file(path_builder.to_string())
    @json.inspect(content, content="Hello, Moonbit!")
    let path_builder = @path.PathBuilder::from_path(path)
    path_builder.add_directory("worktree")
    let stdout = StringBuilder::new()
    @json.inspect(
      @spawn.spawn(
        "git",
        ["branch", "--show-current"],
        cwd=path_builder.to_string(),
        stdout~,
      ),
      content=0,
    )
    inspect(
      stdout.to_string(),
      content=(
        #|new-branch
        #|
      ),
    )
  })
}

///|
pub async fn rev_parse(commit : String, cwd? : StringView) -> String {
  let output = StringBuilder::new()
  let status = @spawn.spawn(
    "git",
    ["rev-parse", commit],
    cwd?,
    stdout=output,
    stderr=output,
  )
  guard status is 0 else {
    fail("git rev-parse failed with \{status}:\n\{output.to_string()}")
  }
  return output.to_string().trim_space().to_string()
}

///|
async test "add_worktree/new-branch-with-commit" (t : @test.T) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    let file = mock.add_file("file.txt", content="Hello, Moonbit!")
    @git.commit("Initial commit", ["file.txt"], cwd=mock.cwd.path())
    let commit = rev_parse("HEAD", cwd=mock.cwd.path())
    file.write("Hello, Moonbit! Version 2")
    @git.commit("Second commit", ["file.txt"], cwd=mock.cwd.path())
    @git.add_worktree(
      "worktree",
      new_branch="new-branch",
      commit~,
      cwd=mock.cwd.path(),
    )
    mock.group.add_defer(() => @git.remove_worktree(
      "worktree",
      force=true,
      cwd=mock.cwd.path(),
    ))
    let cwd = mock.cwd.path()
    let path = @path.Path::parse(cwd + "/")
    let path_builder = @path.PathBuilder::from_path(path)
    path_builder.add_directory("worktree")
    path_builder.set_file(base="file", extension="txt")
    let content = @fs.read_file(path_builder.to_string())
    @json.inspect(content, content="Hello, Moonbit!")
  })
}

///|
async test "with_worktree" (t : @test.T) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    let _ = mock.add_file("file.txt", content="Hello, Moonbit!")
    @git.commit("Initial commit", ["file.txt"], cwd=mock.cwd.path())
    @git.with_worktree("worktree", cwd=mock.cwd.path(), () => {
      let cwd = mock.cwd.path()
      let path = @path.Path::parse(cwd + "/")
      let path_builder = @path.PathBuilder::from_path(path)
      path_builder.add_directory("worktree")
      path_builder.set_file(base="file", extension="txt")
      let content = @fs.read_file(path_builder.to_string())
      @json.inspect(content, content="Hello, Moonbit!")
    })
    let entries = mock.cwd.list().map((entry : @mock.Entry) => entry.name())
    @json.inspect(!entries.contains("worktree"), content=true)
  })
}
