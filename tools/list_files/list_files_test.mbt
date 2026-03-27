///|
async test "list_files" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    mock.add_json_tree({
      "moon.pkg.json": "{}",
      "tool.mbt": "// tool",
      "tool_test.mbt": "// test",
    })
    let tool = @list_files.new(manager)
    let result = tool.call({ "path": "." })
    guard result is Success(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output.to_message().content(),
      content=(
        #|Directory: .
        #|Total: 3 items (3 files, 0 directories)
        #|
        #|📄 tool.mbt
        #|📄 moon.pkg.json
        #|📄 tool_test.mbt
      ),
    )
  })
}

///|
async test "list_files_invalid_symlink" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    mock.add_json_tree({ "file1.txt": "content1" })
    mock.add_symlink("invalid_link.txt", to="non_existent_file.txt")
    let tool = @list_files.new(manager)
    let result = tool.call({ "path": "." })
    guard result is Success(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output.to_message().content(),
      content=(
        #|Directory: .
        #|Total: 2 items (1 files, 0 directories)
        #|
        #|📄 file1.txt
        #|🔗 invalid_link.txt
      ),
    )
  })
}
