///|
test "timeout" {
  @async.with_event_loop(_ => @json.inspect(
    @execute_command.execute_command.call(
      { "command": "sleep", "arguments": ["5"], "timeout": 1 },
      @tool.context(model=@mock.model(), cwd="."),
    ),
    content={
      "output": "Timeout when executing command",
      "error": [
        "TimeoutError",
        { "command": "sleep", "arguments": ["5"], "timeout": 1 },
      ],
    },
  ))
}

///|
test "cat" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-execute-command-test")
    g.add_defer(() => cwd.close())
    let _ = cwd.add_file("file.txt", "hello world")
    let result = @execute_command.execute_command.call(
      { "command": "cat", "arguments": ["file.txt"], "timeout": 5000 },
      @tool.context(model=@mock.model(), cwd=cwd.path()),
    )
    @json.inspect(
      result.output,
      content=(
        #|Exit code: 0
        #|Output:
        #|hello world
      ),
    )
  })
}
