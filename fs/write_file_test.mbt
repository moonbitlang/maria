///|
async test "write_bytes_to_file" {
  @async.with_task_group(g => {
    let dir = @mock.directory("fs-write_bytes_to_file")
    g.add_defer(() => dir.close())
    let file = dir.add_file("example.txt", "")
    @this.write_bytes_to_file(file.path(), "Hello, Moonbit!")
    let content = @this.read_file_to_bytes(file.path())
    @json.inspect(content, content="Hello, Moonbit!")
  })
}

///|
async test "write_to_file" {
  @async.with_task_group(g => {
    let dir = @mock.directory("fs-write_file")
    g.add_defer(() => dir.close())
    let file = dir.add_file("example.txt", "")
    @this.write_to_file(file.path(), "Hello, Moonbit!")
    let content = @this.read_file(file.path())
    @json.inspect(content, content="Hello, Moonbit!")
  })
}
