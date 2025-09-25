///|
async test "make_directory" {
  @async.with_task_group(g => {
    let dir = @mock.directory("fs-make_directory")
    g.add_defer(() => dir.close())
    let dir_a = @path.join(dir.path(), "a")
    let dir_b = @path.join(dir_a, "b")
    @this.make_directory(dir_b, recursive=true)
    @json.inspect(dir.strip_cwd(@this.list_directory(dir.path())), content=[
      { "path": "./a", "name": "a", "kind": "Directory" },
    ])
    @json.inspect(dir.strip_cwd(@this.list_directory(dir_a)), content=[
      { "path": "./a/b", "name": "b", "kind": "Directory" },
    ])
  })
}
