///|
async test "check-ignore" (t : @test.Test) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    let _ = mock.add_file(".gitignore", content="ignored.txt\n")
    let _ = mock.add_file("ignored.txt", content="This file is ignored.")
    let _ = mock.add_file(
      "not_ignored.txt",
      content="This file is not ignored.",
    )
    let ignored_files = @git.check_ignore(
      ["ignored.txt", "not_ignored.txt"],
      cwd=mock.cwd.path(),
    )
    @json.inspect(ignored_files, content=["ignored.txt"])
  })
}
