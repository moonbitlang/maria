///|
test "todo_write/create" {
  @global.set_seed()
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

///|
test "todo_write/update" {
  @global.set_seed()
  @async.with_event_loop(group => {
    let cwd = @mock.directory("tool-todo_write")
    group.add_defer(() => cwd.close())
    let manager = @todo.Manager::new(cwd=cwd.path())
    manager.load()
    let todo1 = manager.add_task("First item", priority=Medium)
    let _ = manager.add_task("Second item", priority=Low)
    manager.save()
    let result = @todo_write.todo_write.call(
      {
        "action": "update",
        "task_id": todo1.id,
        "status": "in-progress",
        "priority": "high",
        "content": "Updated first item",
      },
      @tool.context(cwd=cwd.path()),
    )
    inspect(
      result.output,
      content=(
        #|✅ Operation completed: Updated task: Updated first item
        #|
        #|📝 Current todo list:
        #|  🔴 🔄 [a516463d] Updated first item
        #|  🟢 ⏳ [7c288d41] Second item
        #|
        #|✨ Updated items:
        #|  🔴 🔄 [a516463d] Updated first item
        #|
        #|📊 Current summary: Total 2 items | Pending 1 | In Progress 1 | Completed 0
      ),
    )
  })
}
