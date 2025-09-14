///|
test "todo_write create" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("todo_write")
    g.add_defer(() => cwd.close())
    let result = (todo_write.f)(
      {
        "action": "create",
        "content": "Test todo item\nAnother test item",
        "priority": "high",
      },
      @tool.context(cwd=cwd.path()),
    )
    // Just verify it doesn't error and succeeds
    @json.inspect(result.error, content=null)
    inspect(
      result.output.has_prefix("✅ Operation completed:"),
      content="true",
    )
  })
}
