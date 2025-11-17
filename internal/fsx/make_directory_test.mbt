///|
async test "make_directory" (t : @test.Test) {
  @mock.run(t, mock => {
    let dir_a = @path.join(mock.cwd.path(), "a")
    let dir_b = @path.join(dir_a, "b")
    @this.make_directory(dir_b, recursive=true)
    @json.inspect(mock.json(@this.list_directory(mock.cwd.path())), content=[
      { "path": "(mock:cwd)/a", "name": "a", "kind": "Directory" },
    ])
    @json.inspect(mock.json(@this.list_directory(dir_a)), content=[
      { "path": "(mock:cwd)/a/b", "name": "b", "kind": "Directory" },
    ])
  })
}

///|
async test "make_directory-recursive" (t : @test.Test) {
  @mock.run(t, _mock => @this.make_directory("a/b/c", recursive=true))
}
