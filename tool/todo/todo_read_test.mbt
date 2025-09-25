///|
async test "todo_read" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-todo_read")
    g.add_defer(() => cwd.close())
    let todo_list = @todo.list(rand~, cwd=cwd.path())
    @json.inspect(@todo.read.call({}, todo_list), content={ "output": [] })
    let _ = @todo.write.call(
      { "action": "create", "content": "A sample task", "priority": "medium" },
      todo_list,
    )
    let result = @todo.read.call({}, todo_list)
    inspect(
      (@todo.read.render)(result),
      content=(
        #|=== Current Session Todo List ===
        #|
        #|1. ⏳ 🟡 [b773b606] A sample task
        #|
        #|📊 Summary: Total: 1 | ⏳ Pending: 1
      ),
    )
  })
}
