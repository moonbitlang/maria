///|
async test "add_worktree" (t : @test.Test) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    mock.add_json_tree({ "file.txt": "Hello, Moonbit!" })
    @git.commit("Initial commit", ["file.txt"], cwd=mock.cwd.path())
    @git.add_worktree("worktree", cwd=mock.cwd.path())
    mock.group.add_defer(() => @git.remove_worktree(
      "worktree",
      force=true,
      cwd=mock.cwd.path(),
    ))
    @json.inspect(
      mock.cwd.path()
      |> @pathx.join("worktree")
      |> @pathx.join("file.txt")
      |> @fsx.read_file(),
      content="Hello, Moonbit!",
    )
  })
}

///|
async test "add_worktree/new-branch" (t : @test.Test) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    mock.add_json_tree({ "file.txt": "Hello, Moonbit!" })
    @git.commit("Initial commit", ["file.txt"], cwd=mock.cwd.path())
    @git.add_worktree("worktree", new_branch="new-branch", cwd=mock.cwd.path())
    mock.group.add_defer(() => @git.remove_worktree(
      "worktree",
      force=true,
      cwd=mock.cwd.path(),
    ))
    @json.inspect(
      mock.cwd.path()
      |> @pathx.join("worktree")
      |> @pathx.join("file.txt")
      |> @fsx.read_file(),
      content="Hello, Moonbit!",
    )
    let process = @spawn.spawn(
      "git",
      ["branch", "--show-current"],
      cwd=mock.cwd.path() |> @pathx.join("worktree"),
    )
    inspect(
      process.stdout,
      content=(
        #|new-branch
        #|
      ),
    )
  })
}

///|
pub async fn rev_parse(commit : String, cwd? : StringView) -> String {
  let process = @spawn.spawn("git", ["rev-parse", commit], cwd?)
  process.check()
  return process.stdout.trim().to_string()
}

///|
async test "add_worktree/new-branch-with-commit" (t : @test.Test) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    let file = mock.add_file("file.txt", content="Hello, Moonbit!")
    @git.commit("Initial commit", ["file.txt"], cwd=mock.cwd.path())
    let commit = rev_parse("HEAD", cwd=mock.cwd.path())
    file.write_string("Hello, Moonbit! Version 2")
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
    @json.inspect(
      mock.cwd.path()
      |> @pathx.join("worktree")
      |> @pathx.join("file.txt")
      |> @fsx.read_file(),
      content="Hello, Moonbit!",
    )
  })
}

///|
async test "with_worktree" (t : @test.Test) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    mock.add_json_tree({ "file.txt": "Hello, Moonbit!" })
    @git.commit("Initial commit", ["file.txt"], cwd=mock.cwd.path())
    @git.with_worktree("worktree", cwd=mock.cwd.path(), () => @json.inspect(
      mock.cwd.path()
      |> @pathx.join("worktree")
      |> @pathx.join("file.txt")
      |> @fsx.read_file(),
      content="Hello, Moonbit!",
    ))
    let entries = mock.cwd.list().map((entry : @mock.Entry) => entry.name())
    @json.inspect(!entries.contains("worktree"), content=true)
  })
}
