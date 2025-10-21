///|
async test "todo_read" (t : @test.T) {
  @mock.run(t, taco => {
    let todo_list = @todo.list(uuid=taco.uuid, cwd=taco.cwd.path())
    @json.inspect(@todo_read.todo_read.call({}, todo_list), content={
      "output": "=== Current Session Todo List ===\n\n\n📊 Summary: Total: 0",
    })
    @json.inspect(@todo_read.todo_read.call({}, todo_list), content={
      "output": "=== Current Session Todo List ===\n\n\n📊 Summary: Total: 0",
    })
    let _ = @todo_write.todo_write.call(
      { "action": "create", "content": "A sample task", "priority": "medium" },
      todo_list,
    )
    let result = @todo_read.todo_read.call({}, todo_list)
    inspect(
      result.output,
      content=(
        #|=== Current Session Todo List ===
        #|
        #|1. ⏳ 🟡 [ac8a366d] A sample task
        #|
        #|📊 Summary: Total: 1 | ⏳ Pending: 1
      ),
    )
  })
}
