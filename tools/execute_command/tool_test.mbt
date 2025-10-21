///|
async test "timeout" (t : @test.T) {
  @mock.run(t, mock => @async.with_task_group(_ => @json.inspect(
    @execute_command.execute_command.call(
      { "command": "sleep", "arguments": ["5"], "timeout": 1 },
      @job.Manager::new(cwd=mock.cwd.path()),
    ),
    content={
      "output": "Timeout when executing command",
      "error": ["TimeoutError", { "command": "sleep", "timeout": 1 }],
    },
  )))
}

///|
async test "cat" (t : @test.T) {
  @mock.run(t, taco => {
    let _ = taco.add_file("file.txt", content="hello world")
    let result = @execute_command.execute_command.call(
      { "command": "cat file.txt", "timeout": 5000 },
      @job.Manager::new(cwd=taco.cwd.path()),
    )
    inspect(
      result.output,
      content=(
        #|Command: cat file.txt
        #|Exit code: 0
        #|Output:
        #|hello world
      ),
    )
  })
}

///|
async test "output-overflow" (t : @test.T) {
  @mock.run(t, taco => {
    let lines = []
    for i = 0; i < 100; i = i + 1 {
      lines.push("hello")
    }
    let _ = taco.add_file("file.txt", content=lines.join("\n"))
    let result = @execute_command.execute_command.call(
      { "command": "cat file.txt", "timeout": 5000, "max_output_lines": 5 },
      @job.Manager::new(cwd=taco.cwd.path()),
    )
    // For output-overflow case, we can't predict the exact UUID in the output_file path
    // So we'll check the structure and key fields, allowing flexibility for the UUID
    inspect(
      result.output,
      content=(
        #|Command: cat file.txt
        #|Exit code: 0
        #|Output: (first 5 of 100 lines)
        #|hello
        #|hello
        #|hello
        #|hello
        #|hello
        #|... (truncated, try using redirection to pipe output to a file) ...
      ),
    )
  })
}

///|
async test "cd" (t : @test.T) {
  @mock.run(t, taco => {
    let _ = taco.add_file("file.txt", content="hello world")
    let result = @execute_command.execute_command.call(
      { "command": "cat file.txt", "timeout": 5000 },
      @job.Manager::new(cwd=taco.cwd.path()),
    )
    @json.inspect(
      result.output,
      content="Command: cat file.txt\nExit code: 0\nOutput:\nhello world",
    )
    let _ = taco
      .add_directory("subdir")
      .add_file("file.txt", content="hello from subdir")
    let result = @execute_command.execute_command.call(
      { "command": "cd subdir && cat file.txt", "timeout": 5000 },
      @job.Manager::new(cwd=taco.cwd.path()),
    )
    inspect(
      result.output,
      content=(
        #|Command: cd subdir && cat file.txt
        #|Exit code: 0
        #|Output:
        #|hello from subdir
      ),
    )
  })
}

///|
async test "background" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @job.Manager::new(cwd=taco.cwd.path())
    taco.group.spawn_bg(() => manager.start(), no_wait=true)
    let result = @execute_command.execute_command.call(
      { "command": "sleep 2", "background": true },
      manager,
    )
    inspect(
      result.output,
      content=(
        #|Command: sleep 2
        #|Started in background with Job ID: 0
      ),
    )
  })
}
