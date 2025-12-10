///|
async test "read_file" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({ "example.txt": "Hello, Moonbit!" })
    let file_path = @path.join(mock.cwd.path(), "example.txt")
    let content = @fsx.read_file(file_path)
    @json.inspect(content, content="Hello, Moonbit!")
  })
}
