///|
async test "list_files" (t : @test.Test) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    mock.cwd.add_file("file1.txt").write_string("Content 1")
    json_inspect(@git.list_files(cwd=mock.cwd.path()), content=[])
  })
}
