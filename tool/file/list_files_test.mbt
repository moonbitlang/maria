///|
test "list_files" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-list-files-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let _ = cwd.add_file("moon.pkg.json", "{}")
    let _ = cwd.add_file("tool.mbt", "// tool")
    let _ = cwd.add_file("tool_test.mbt", "// test")
    @json.inspect(@file.list_files.call({ "path": "." }, manager).output, content={
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
