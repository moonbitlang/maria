///|
test "read_file_to_bytes" {
  @async.with_event_loop(g => {
    let dir = @mock.directory("fs-read_file")
    g.add_defer(() => dir.close())
    let file = dir.add_file("example.txt", "Hello, Moonbit!")
    let content = @this.read_file_to_bytes(file.path())
    @json.inspect(content, content="Hello, Moonbit!")
  })
}

///|
test "read_file" {
  @async.with_event_loop(g => {
    let dir = @mock.directory("fs-read_file")
    g.add_defer(() => dir.close())
    let file = dir.add_file("example.txt", "Hello, Moonbit!")
    let content = @this.read_file(file.path())
    @json.inspect(content, content="Hello, Moonbit!")
  })
}
