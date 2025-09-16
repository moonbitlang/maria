///|
test "make_directory" {
  @async.with_event_loop(_ => {
    let dir = @mock.directory("fs-make_directory")
    let dir_a = @path.join(dir.path(), "a")
    let dir_b = @path.join(dir_a, "b")
    @this.make_directory(dir_b, recursive=true)
    @json.inspect(@this.list_directory(dir.path()), content=["a/"])
    @json.inspect(@this.list_directory(dir_a), content=["b/"])
  })
}
