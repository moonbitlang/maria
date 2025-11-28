///|
async test "read_file" (t : @test.Test) {
  @mock.run(t, mock => {
    let file = mock.add_file("example.txt", content="Hello, Moonbit!")
    let content = @fsx.read_file(file.path())
    @json.inspect(content, content="Hello, Moonbit!")
  })
}
