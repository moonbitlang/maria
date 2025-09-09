///|
test "list_files" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-list-files-test")
    g.add_defer(() => cwd.close())
    cwd.add_file("moon.pkg.json", "{}")
    cwd.add_file("tool.mbt", "// tool")
    cwd.add_file("tool_test.mbt", "// test")
    inspect(
      (list_files.f)({ "path": "." }, @tool.context(cwd=cwd.path())).output,
      content=(
        #|tool.mbt
        #|moon.pkg.json
        #|tool_test.mbt
      ),
    )
  })
}
