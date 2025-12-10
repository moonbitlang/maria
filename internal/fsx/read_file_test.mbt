///|
async test "read_file" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({ "example.txt": "Hello, Moonbit!" })
    let content = @fsx.read_file(@path.join(mock.cwd.path(), "example.txt"))
    @json.inspect(content, content="Hello, Moonbit!")
  })
}
