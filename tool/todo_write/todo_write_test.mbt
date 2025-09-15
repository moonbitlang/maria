///|
test "todo_write create" {
  @g.set_seed()
  @async.with_event_loop(group => {
    let cwd = @mock.directory("tool-todo_write")
    group.add_defer(() => cwd.close())
    let result = (todo_write.f)(
      {
        "action": "create",
        "content": "Test todo item\nAnother test item",
        "priority": "high",
      },
      @tool.context(cwd=cwd.path()),
    )
    inspect(
      result.output,
      content=(
        #|✅ Operation completed: Created 2 new todo items
        #|
        #|📝 Newly created todos:
        #|  🔴 ⏳ [a516463d] Test todo item
        #|  🔴 ⏳ [7c288d41] Another test item
        #|
        #|📊 Current summary: Total 2 items | Pending 2 | In Progress 0 | Completed 0
      ),
    )
  })
}
