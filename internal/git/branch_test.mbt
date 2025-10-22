///|
async test "branch" (t : @test.T) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    let _ = mock.add_file("file.txt", content="Hello, Moonbit!")
    @git.commit("Initial commit", ["file.txt"], cwd=mock.cwd.path())
    @git.create_branch("new-branch", cwd=mock.cwd.path())
    let stdout = StringBuilder::new()
    @json.inspect(
      @spawn.spawn("git", ["branch", "--list"], cwd=mock.cwd.path(), stdout~),
      content=0,
    )
    inspect(
      stdout.to_string(),
      content=(
        #|* main
        #|  new-branch
        #|
      ),
    )
    @git.delete_branch("new-branch", cwd=mock.cwd.path())
    let stdout = StringBuilder::new()
    @json.inspect(
      @spawn.spawn("git", ["branch", "--list"], cwd=mock.cwd.path(), stdout~),
      content=0,
    )
    inspect(
      stdout.to_string(),
      content=(
        #|* main
        #|
      ),
    )
  })
}
