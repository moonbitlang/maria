///|
async test "nonexistent" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    let args : Json = { "path": "nonexistent.txt" }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    inspect(
      result,
      content="Error reading file: File not found: nonexistent.txt",
    )
    @json.inspect(result, content=[
      "Error",
      ["ToolFailure", "Error reading file: File not found: nonexistent.txt"],
      "Error reading file: File not found: nonexistent.txt",
    ])
  })
}

///|
async test "content" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    let _ = taco.add_file(
      "test.txt",
      content=(
        #|line 1
        #|line 2
        #|line 3
        #|line 4
      ),
    )
    let args : Json = { "path": "test.txt" }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content=[
      "ReadFileResult",
      {
        "path": "test.txt",
        "content": "line 1\nline 2\nline 3\nline 4",
        "start_line": 1,
        "end_line": 4,
      },
    ])
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|File: test.txt (lines 1-4 (4 lines))
        #|line 1
        #|line 2
        #|line 3
        #|line 4
      ),
    )
  })
}

///|
async test "line_range" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    let _ = taco.add_file(
      "lines.txt",
      content=(
        #|line 1
        #|line 2
        #|line 3
        #|line 4
        #|line 5
      ),
    )
    let args : Json = { "path": "lines.txt", "start_line": 2, "end_line": 4 }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content=[
      "ReadFileResult",
      {
        "path": "lines.txt",
        "content": "line 1\nline 2\nline 3\nline 4\nline 5",
        "start_line": 2,
        "end_line": 4,
      },
    ])
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|File: lines.txt (lines 2-4 (3 lines))
        #|line 2
        #|line 3
        #|line 4
      ),
    )
  })
}

///|
async test "directory" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    taco.add_files([("file1.txt", "content1"), ("file2.txt", "content2")])
    let subdir = taco.add_directory("subdir")
    let _ = subdir.add_file("file3.txt", content="content3")
    let args : Json = { "path": "." }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content=[
      "ReadDirectoryResult",
      {
        "path": ".",
        "entries": ["subdir/", "file1.txt", "file2.txt"],
        "display": "subdir/\nfile1.txt\nfile2.txt",
      },
    ])
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|Directory: .
        #|Entries:
        #|subdir/
        #|file1.txt
        #|file2.txt
      ),
    )
  })
}

///|
async test "invalid-range" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    let _ = taco.add_file(
      "test.txt",
      content=(
        #|line 1
        #|line 2
        #|line 3
      ),
    )
    let args : Json = { "path": "test.txt", "start_line": 3, "end_line": 2 }
    let result = new(manager).call(args)
    inspect(
      result,
      content="Error: end_line (2) must be greater than start_line (3)",
    )
    let args : Json = { "path": "test.txt", "start_line": 0 }
    let result = new(manager).call(args)
    inspect(result, content="Error: start_line must be >= 1, got 0")
    let args : Json = { "path": "test.txt", "start_line": 2, "end_line": 1024 }
    let tool = new(manager)
    let result = tool.call(args)
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content=[
      "ReadFileResult",
      {
        "path": "test.txt",
        "content": "line 1\nline 2\nline 3",
        "start_line": 2,
        "end_line": 3,
      },
    ])
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output,
      content=(
        #|File: test.txt (lines 2-3 (2 lines))
        #|line 2
        #|line 3
      ),
    )
  })
}
