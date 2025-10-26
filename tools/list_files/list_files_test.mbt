///|
async test "list_files" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    taco.add_files([
      ("moon.pkg.json", "{}"),
      ("tool.mbt", "// tool"),
      ("tool_test.mbt", "// test"),
    ])
    let tool = @list_files.new(manager)
    let result = tool.call({ "path": "." })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content={
      "path": ".",
      "entries": [
        { "name": "tool.mbt", "kind": "file", "is_hidden": false },
        { "name": "moon.pkg.json", "kind": "file", "is_hidden": false },
        { "name": "tool_test.mbt", "kind": "file", "is_hidden": false },
      ],
      "total_count": 3,
      "file_count": 3,
      "directory_count": 0,
    })
  })
}
