///|
async test "timeout" (t : @test.T) {
  @mock.run(t, mock => @async.with_task_group(_ => {
    let tool = @execute_command.new(@job.Manager::new(cwd=mock.cwd.path()))
    @json.inspect(
      tool.call({ "command": "sleep", "arguments": ["5"], "timeout": 1 }),
      content=[
        "Error",
        ["TimeoutError", { "command": "sleep", "timeout": 1 }],
        "Timeout when executing command sleep after 1 ms",
      ],
    )
  }))
}

///|
async test "timeout-with-partial-output" (t : @test.T) {
  @mock.run(t, mock => @async.with_task_group(_ => {
    let tool = @execute_command.new(@job.Manager::new(cwd=mock.cwd.path()))
    // This command outputs 'a', sleeps, outputs 'b', sleeps, outputs 'c'
    // With a 1500ms timeout, we should see 'a' and possibly 'b' in the output
    let result = tool.call({
      "command": "sh -c 'echo a; sleep 1; echo b; sleep 1; echo c'",
      "timeout": 1500,
    })
    guard result is Error(_, message) else {
      fail("Expected Error result but got: \{result}")
    }
    // Verify the error message contains the timeout information
    if not(message.contains("Timeout when executing command")) {
      fail("Expected timeout error message but got: \{message}")
    }
    // Verify that partial output is included in the error message
    if not(message.contains("a")) {
      fail("Expected partial output 'a' in error message but got: \{message}")
    }
  }))
}

///|
async test "cat" (t : @test.T) {
  @mock.run(t, taco => {
    let _ = taco.add_file("file.txt", content="hello world")
    let tool = @execute_command.new(@job.Manager::new(cwd=taco.cwd.path()))
    let result = tool.call({ "command": "cat file.txt", "timeout": 5000 })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content=[
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
    let tool = @execute_command.new(@job.Manager::new(cwd=taco.cwd.path()))
    let result = tool.call({
      "command": "cat file.txt",
      "timeout": 5000,
      "max_output_lines": 5,
    })
    // For output-overflow case, we can't predict the exact UUID in the output_file path
    // So we'll check the structure and key fields, allowing flexibility for the UUID
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content=[
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
    let tool = @execute_command.new(@job.Manager::new(cwd=taco.cwd.path()))
    let result = tool.call({ "command": "cat file.txt", "timeout": 5000 })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content=[
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
    let tool = @execute_command.new(@job.Manager::new(cwd=taco.cwd.path()))
    let result = tool.call({
      "command": "cd subdir && cat file.txt",
      "timeout": 5000,
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content=[
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
    let tool = @execute_command.new(manager)
    let result = tool.call({ "command": "sleep 2", "background": true })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content=[
      "Background",
      { "command": "sleep 2", "job_id": 0 },
    ])
  })
}
