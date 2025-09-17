///|
test "todo_read" {
  @rand.seed()
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-todo_read")
    g.add_defer(() => cwd.close())
    let context = @tool.context(cwd=cwd.path())
    let manager = @todo.Manager::new(cwd=cwd.path())
    @json.inspect(@todo_read.todo_read.call({}, context), content={
      "output": "No todos found for this session.",
    })
    let _ = manager.add_task("A sample task")
    manager.save()
    inspect(
      @todo_read.todo_read.call({}, context).output,
      content=(
        #|=== Current Session Todo List ===
        #|
        #|1. ⏳ 🟡 [a516463d] A sample task
        #|
        #|📊 Summary: Total: 1 | ⏳ Pending: 1
      ),
    )
  })
}
