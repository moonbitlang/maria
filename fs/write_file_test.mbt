///|
test "write_bytes_to_file" {
  @async.with_event_loop(g => {
    let dir = @mock.directory("fs-write_file")
    g.add_defer(() => dir.close())
    let file = dir.add_file("example.txt", "")
    @fs.write_bytes_to_file(file.path(), "Hello, Moonbit!")
    let content = @fs.read_file_to_bytes(file.path())
    @json.inspect(content, content="Hello, Moonbit!")
  })
}

///|
test "write_to_file" {
  @async.with_event_loop(g => {
    let dir = @mock.directory("fs-write_file")
    g.add_defer(() => dir.close())
    let file = dir.add_file("example.txt", "")
    @fs.write_to_file(file.path(), "Hello, Moonbit!")
    let content = @fs.read_file(file.path())
    @json.inspect(content, content="Hello, Moonbit!")
  })
}
