///|
async test "list_files" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-list-files-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let _ = cwd.add_file("moon.pkg.json", "{}")
    let _ = cwd.add_file("tool.mbt", "// tool")
    let _ = cwd.add_file("tool_test.mbt", "// test")
    inspect(
      @file.list_files.call({ "path": "." }, manager).output,
      content=(
        #|tool.mbt
        #|moon.pkg.json
        #|tool_test.mbt
      ),
    )
  })
}
