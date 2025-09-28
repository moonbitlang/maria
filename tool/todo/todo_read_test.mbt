///|
async test "todo_read" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-todo_read")
    g.add_defer(() => cwd.close())
    let todo_list = @todo.list(rand~, cwd=cwd.path())
<<<<<<< HEAD
<<<<<<< HEAD
    @json.inspect(@todo.read.call({}, todo_list), content={
      "output": { "todos": [] },
    })
=======
    @json.inspect(@todo.read.call({}, todo_list), content={ "output": [] })
>>>>>>> 1bbeab9 (fix: update tests)
=======
    @json.inspect(@todo.read.call({}, todo_list), content={
      "output": { "todos": [] },
    })
>>>>>>> 6e1a276 (Add JSON serialization support for tool result structures by defining structured result types with ToJson/FromJson implementations across multiple tool modules including execute_command, file, search_files, and todo. Modified files include tool/*/pkg.generated.mbti to add result structs with JSON derives, updated write_to_file.mbt to expose WriteResult struct, refactored meta_write_to_file/tool.mbt to use MetaWriteToFileResult with proper JSON serialization, and fixed todo_read_test.mbt to expect JSON object output instead of array.)
    let _ = @todo.write.call(
      { "action": "create", "content": "A sample task", "priority": "medium" },
      todo_list,
    )
    let result = @todo.read.call({}, todo_list)
    inspect(
      (@todo.read.render)(result),
      content=(
        #|Error: Unexpected output format: JsonDecodeError(($, "Array::from_json: expected array"))
      ),
    )
  })
}
