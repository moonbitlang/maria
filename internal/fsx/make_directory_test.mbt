///|
async test "make_directory" (t : @test.Test) {
  @mock.run(t, mock => {
    let dir_a = @pathx.join(mock.cwd.path(), "a")
    let dir_b = @pathx.join(dir_a, "b")
    @fsx.make_directory(dir_b, recursive=true)
    @json.inspect(mock.json(@fsx.list_directory(mock.cwd.path())), content=[
      { "path": "(mock:cwd)/a", "name": "a", "kind": "Directory" },
    ])
    @json.inspect(mock.json(@fsx.list_directory(dir_a)), content=[
      { "path": "(mock:cwd)/a/b", "name": "b", "kind": "Directory" },
    ])
  })
}

///|
async test "make_directory-recursive" (t : @test.Test) {
  @mock.run(t, _mock => @fsx.make_directory("a/b/c", recursive=true))
}
