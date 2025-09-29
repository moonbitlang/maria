///|
async test "timeout" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @async.with_task_group(_ => @json.inspect(
    @execute_command.execute_command.call(
      { "command": "sleep", "arguments": ["5"], "timeout": 1 },
      @execute_command.context(rand~, cwd="."),
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
async test "cat" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-execute-command-test")
    g.add_defer(() => cwd.close())
    let _ = cwd.add_file("file.txt", "hello world")
    let result = @execute_command.execute_command.call(
      { "command": "cat", "arguments": ["file.txt"], "timeout": 5000 },
      @execute_command.context(rand~, cwd=cwd.path()),
    )
    @json.inspect(result.output, content={
      "command": "cat",
      "arguments": ["file.txt"],
      "exit_code": 0,
      "output": "hello world",
      "truncated": false,
      "total_lines": 1,
      "timeout_ms": 5000,
    })
  })
}

///|
async test "output-overflow" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @async.with_task_group(group => {
    let cwd = @mock.directory("tool-execute-command-output-overflow-test")
    group.add_defer(() => cwd.close())
    let lines = []
    for i = 0; i < 100; i = i + 1 {
      lines.push("hello")
    }
    let _ = cwd.add_file("file.txt", lines.join("\n"))
    let result = @execute_command.execute_command.call(
      {
        "command": "cat",
        "arguments": ["file.txt"],
        "timeout": 5000,
        "max_output_lines": 5,
      },
      @execute_command.context(rand~, cwd=cwd.path()),
    )
    // For output-overflow case, we can't predict the exact UUID in the output_file path
    // So we'll check the structure and key fields, allowing flexibility for the UUID
    @json.inspect(result.output.as_object().unwrap()["command"], content="cat")
    @json.inspect(result.output.as_object().unwrap()["arguments"], content=[
      "file.txt",
    ])
    @json.inspect(result.output.as_object().unwrap()["exit_code"], content=0)
    @json.inspect(
      result.output.as_object().unwrap()["output"],
      content="hello\nhello\nhello\nhello\nhello",
    )
    @json.inspect(result.output.as_object().unwrap()["truncated"], content=true)
    @json.inspect(
      result.output.as_object().unwrap()["total_lines"],
      content=100,
    )
    @json.inspect(
      result.output.as_object().unwrap()["timeout_ms"],
      content=5000,
    )
  })
}

///|
async test "cd" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @async.with_task_group(group => {
    let cwd = @mock.directory("tool-execute-command-output-overflow-test")
    group.add_defer(() => cwd.close())
    let result = @execute_command.execute_command.call(
      { "command": "cd", "arguments": [".."], "timeout": 5000 },
      @execute_command.context(rand~, cwd=cwd.path()),
    )
    @json.inspect(result, content={
      "output": "Error: 'cd' command is not allowed. It makes no sense to change directory in a subprocess, as the working directory of parent process remains unchanged.",
      "error": "moonbitlang/maria/tool.Failure.Failure",
    })
  })
}

///|
async test "working_directory" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @async.with_task_group(group => {
    let cwd = @mock.directory("tool-execute-command-working-directory-test")
    group.add_defer(() => cwd.close())
    let _ = cwd.add_file("file.txt", "hello world")
    let result = @execute_command.execute_command.call(
      {
        "command": "cat",
        "arguments": ["file.txt"],
        "timeout": 5000,
        "working_directory": ".",
      },
      @execute_command.context(rand~, cwd=cwd.path()),
    )
    @json.inspect(result.output, content={
      "command": "cat",
      "arguments": ["file.txt"],
      "exit_code": 0,
      "output": "hello world",
      "truncated": false,
      "total_lines": 1,
      "timeout_ms": 5000,
    })
    let _ = cwd.add_file("subdir/file.txt", "hello from subdir")
    let result = @execute_command.execute_command.call(
      {
        "command": "cat",
        "arguments": ["file.txt"],
        "timeout": 5000,
        "working_directory": "subdir",
      },
      @execute_command.context(rand~, cwd=cwd.path()),
    )
    @json.inspect(result.output, content={
      "command": "cat",
      "arguments": ["file.txt"],
      "exit_code": 0,
      "output": "hello from subdir",
      "truncated": false,
      "total_lines": 1,
      "timeout_ms": 5000,
    })
  })
}
