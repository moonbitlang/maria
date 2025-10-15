///|
async test "make_directory" (t : @test.T) {
  @mock.run(t, taco => {
    let dir_a = @path.join(taco.cwd.path(), "a")
    let dir_b = @path.join(dir_a, "b")
    @this.make_directory(dir_b, recursive=true)
    @json.inspect(taco.json(@this.list_directory(taco.cwd.path())), content=[
      { "path": "(mock:cwd)/a", "name": "a", "kind": "Directory" },
    ])
    @json.inspect(taco.json(@this.list_directory(dir_a)), content=[
      { "path": "(mock:cwd)/a/b", "name": "b", "kind": "Directory" },
    ])
  })
}
