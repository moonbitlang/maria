///|
async test "check-ignore" (t : @test.Test) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    mock.add_json_tree({
      ".gitignore": "ignored.txt\n",
      "ignored.txt": "This file is ignored.",
      "not_ignored.txt": "This file is not ignored.",
    })
    let ignored_files = @git.check_ignore(
      ["ignored.txt", "not_ignored.txt"],
      cwd=mock.cwd.path(),
    )
    @json.inspect(ignored_files, content=["ignored.txt"])
  })
}
