///|
async test "read_file" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({ "example.txt": "Hello, Moonbit!" })
    let file_path = Path::join(mock.cwd.path(), "example.txt").to_string()
    let content = @fsx.read_file(file_path)
    json_inspect(content, content="Hello, Moonbit!")
  })
}
