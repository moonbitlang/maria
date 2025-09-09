///|
test "timeout" {
  @async.with_event_loop(_ => @json.inspect(
    (execute_command.f)(
      { "command": "sleep", "arguments": ["5"], "timeout": 1 },
      @tool.context(cwd="."),
    ),
    content={
      "output": "Timeout when executing command",
      "error": [
        "TimeoutError",
        { "command": "sleep", "arguments": ["5"], "timeout": 1000 },
      ],
    },
  ))
}
