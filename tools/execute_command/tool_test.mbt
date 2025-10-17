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
    @json.inspect(result.output, content=[
      "Foreground",
      {
        "command": "cat file.txt",
        "status": 0,
        "output": "hello world",
        "truncated": false,
        "total_lines": 1,
        "timeout": 5000,
      },
    ])
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
    @json.inspect(result.output, content=[
      "Foreground",
      {
        "command": "cat file.txt",
        "status": 0,
        "output": "hello\nhello\nhello\nhello\nhello",
        "truncated": true,
        "total_lines": 100,
        "timeout": 5000,
      },
    ])
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
    @json.inspect(result.output, content=[
      "Foreground",
      {
        "command": "cat file.txt",
        "status": 0,
        "output": "hello world",
        "truncated": false,
        "total_lines": 1,
        "timeout": 5000,
      },
    ])
    let _ = taco
      .add_directory("subdir")
      .add_file("file.txt", content="hello from subdir")
    let result = @execute_command.execute_command.call(
      { "command": "cd subdir && cat file.txt", "timeout": 5000 },
      @job.Manager::new(cwd=taco.cwd.path()),
    )
    @json.inspect(result.output, content=[
      "Foreground",
      {
        "command": "cd subdir && cat file.txt",
        "status": 0,
        "output": "hello from subdir",
        "truncated": false,
        "total_lines": 1,
        "timeout": 5000,
      },
    ])
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
    @json.inspect(result.output, content=[
      "Background",
      { "command": "sleep 2", "job_id": 0 },
    ])
  })
}
