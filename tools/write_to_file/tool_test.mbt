///|
let original =
  #|Line 1
  #|Line 2

///|
async test "write_to_file" (t : @test.Test) {
  @mock.run(t, mock => {
    @fsx.write_to_file(@pathx.join(mock.cwd.path(), "file.txt"), original)
    let args = json_input(path="file.txt", content="Line 3", separator="\n")
    let tool = new(mock.cwd.path())
    let result = tool.call(args)
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(mock.json(output), content={ "path": "(mock:cwd)/file.txt" })
    let final_content = @fsx.read_file(@pathx.join(mock.cwd.path(), "file.txt"))
    inspect(
      final_content,
      content=(
        #|Line 1
        #|Line 2
        #|Line 3
      ),
    )
  })
}

///|
async test "write_to_file/no-write-permission" (t : @test.Test) {
  @mock.run(t, mock => {
    let file_path = @pathx.join(mock.cwd.path(), "file.txt")
    @fsx.write_to_file(file_path, original)
    // Change file to read-only
    @fs.chmod(file_path, 0o444)
    let args = json_input(path="file.txt", content="Line 3", separator="\n")
    let tool = new(mock.cwd.path())
    let result = tool.call(args)
    // Verify that an error is returned
    guard result is Error(_) else {
      fail("Expected Err result but got: \{result}")
    }
    inspect(
      mock.text(result),
      content=(
        #|Failed to write to file: OSError("@fs.open(): \"(mock:cwd)/file.txt\": Permission denied")
      ),
    )
    // Restore write permission for cleanup
    @fs.chmod(file_path, 0o644)
  })
}
