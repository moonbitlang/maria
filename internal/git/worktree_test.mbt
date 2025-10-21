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
    @json.inspect(
      mock.cwd.path()
      |> @path.join("worktree")
      |> @path.join("file.txt")
      |> @fs.read_file(),
      content="Hello, Moonbit!",
    )
  })
}

///|
async test "with_worktree" (t : @test.T) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    let _ = mock.add_file("file.txt", content="Hello, Moonbit!")
    @git.commit("Initial commit", ["file.txt"], cwd=mock.cwd.path())
    @git.with_worktree("worktree", cwd=mock.cwd.path(), () => @json.inspect(
      mock.cwd.path()
      |> @path.join("worktree")
      |> @path.join("file.txt")
      |> @fs.read_file(),
      content="Hello, Moonbit!",
    ))
    let entries = mock.cwd.list().map((entry : @mock.Entry) => entry.name())
    @json.inspect(!entries.contains("worktree"), content=true)
  })
}
