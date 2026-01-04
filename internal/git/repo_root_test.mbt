///|
async test "find_repo_root" (t : @test.Test) {
  @mock.run(t, mock => {
    // Not in a git repo
    inspect(mock.show(@git.find_repo_root(mock.cwd.path())), content="None")

    // Non-existent path
    inspect(
      mock.show(@git.find_repo_root(@pathx.join(mock.cwd.path(), "nope"))),
      content="None",
    )

    // In a git repo
    @git.init_(mock.cwd.path())
    inspect(
      mock.show(@git.find_repo_root(mock.cwd.path())),
      content="Some(\"(mock:cwd)\")",
    )

    // Subdirectory in a git repo
    let sub = mock.cwd.add_directory("sub")
    inspect(
      mock.show(@git.find_repo_root(sub.path())),
      content="Some(\"(mock:cwd)\")",
    )

    // File path in a git repo
    let file = sub.add_file("hello.txt")
    file.write_string("hello")
    inspect(
      mock.show(@git.find_repo_root(file.path())),
      content="Some(\"(mock:cwd)\")",
    )
  })
}
