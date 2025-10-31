///|
async test "todo_read" (t : @test.T) {
  @mock.run(t, taco => {
    let todo_list = @todo.list(uuid=taco.uuid, cwd=taco.cwd.path())
    let read_tool = @todo_read.new(todo_list)
    @json.inspect(read_tool.call({}), content=["Ok", { "todos": [] }])
    let write_tool = @todo_write.new(todo_list)
    let _ = write_tool.call({
      "action": "create",
      "content": "A sample task",
      "priority": "medium",
    })
    let result = read_tool.call({})
    @json.inspect(
      result
      .to_json()
      .transform(@json.Replacer::exclude(["created_at", "updated_at", "id"])),
      content=[
        "Ok",
        {
          "todos": [
            {
              "content": "A sample task",
              "created_at": "2025-10-31T07:28:21",
              "id": "ac8a366d",
              "priority": "Medium",
              "status": "Pending",
              "updated_at": "2025-10-31T07:28:21",
            },
          ],
        },
      ],
    )
  })
}
