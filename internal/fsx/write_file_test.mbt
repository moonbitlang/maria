///|
async test "write_to_file" (t : @test.Test) {
  @mock.run(t, mock => {
    let file = mock.add_file("example.txt", content="")
    @fsx.write_to_file(file.path(), "Hello, Moonbit!")
    let content = @fsx.read_file(file.path())
    json_inspect(content, content="Hello, Moonbit!")
  })
}
