///|
test "make_directory" {
  @async.with_event_loop(_ => {
    let dir = @mock.directory("fs-make_directory")
    let dir_a = @path.join(dir.path(), "a")
    let dir_b = @path.join(dir_a, "b")
    @this.make_directory(dir_b)
    @json.inspect(@this.list_directory(dir.path()).map(@path.basename(_)), content=[
      "a",
    ])
    @json.inspect(@this.list_directory(dir_a).map(@path.basename(_)), content=[
      "b",
    ])
  })
}
