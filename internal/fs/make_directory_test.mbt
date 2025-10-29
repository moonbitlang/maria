///|
async test "make_directory" (t : @test.T) {
  @mock.run(t, taco => {
    let path = @path.Path::parse(taco.cwd.path() + "/")
    let path_builder = @path.PathBuilder::from_path(path)
    path_builder.add_directory("a")
    let dir_a = path_builder.to_string()
    path_builder.add_directory("b")
    let dir_b = path_builder.to_string()
    let dir_b = dir_b[0:dir_b.length() - 1] // workaround for @this.make_directory
    @this.make_directory(dir_b, recursive=true)
    @json.inspect(taco.json(@this.list_directory(taco.cwd.path())), content=[
      { "path": "(mock:cwd)/a", "name": "a", "kind": "Directory" },
    ])
    @json.inspect(taco.json(@this.list_directory(dir_a)), content=[
      { "path": "(mock:cwd)/a/b", "name": "b", "kind": "Directory" },
    ])
  })
}
