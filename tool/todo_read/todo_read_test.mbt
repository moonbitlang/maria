///|
test "todo_read empty" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("todo_read")
    g.add_defer(() => cwd.close())
    let result = (todo_read.f)({}, @tool.context(cwd=cwd.path()))
    inspect(result.output, content="No todos found for this session.")
  })
}
