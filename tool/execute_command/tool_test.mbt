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
    inspect(
      result.output,
      content=(
        #|Exit code: 0
        #|Output: (first 5 lines)
        #|hello
        #|hello
        #|hello
        #|hello
        #|hello
        #|... (truncated, total 100 lines, use <read_file> tool to read full output at .moonagent/processes/b773b606-3d46-46a5-8160-af22a66abc3c/output.txt) ...
      ),
    )
  })
}
