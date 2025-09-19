///|
test "list_files" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-list-files-test")
    g.add_defer(() => cwd.close())
    let _ = cwd.add_file("moon.pkg.json", "{}")
    let _ = cwd.add_file("tool.mbt", "// tool")
    let _ = cwd.add_file("tool_test.mbt", "// test")
    inspect(
      @list_files.list_files.call(
        { "path": "." },
        @tool.context(model=@mock.model(), cwd=cwd.path()),
      ).output,
      content=(
        #|tool.mbt
        #|moon.pkg.json
        #|tool_test.mbt
      ),
    )
  })
}
