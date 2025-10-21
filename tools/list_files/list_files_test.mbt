///|
async test "list_files" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    taco.add_files([
      ("moon.pkg.json", "{}"),
      ("tool.mbt", "// tool"),
      ("tool_test.mbt", "// test"),
    ])
    @json.inspect(
      @list_files.list_files.call({ "path": "." }, manager).output,
      content={
        "path": ".",
        "entries": [
          { "name": "tool.mbt", "kind": "file", "is_hidden": false },
          { "name": "moon.pkg.json", "kind": "file", "is_hidden": false },
          { "name": "tool_test.mbt", "kind": "file", "is_hidden": false },
        ],
        "total_count": 3,
        "file_count": 3,
        "directory_count": 0,
      },
    )
  })
}
