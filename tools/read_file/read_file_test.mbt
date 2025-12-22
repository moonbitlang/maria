///|
async test "nonexistent" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
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
async test "content" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    let _ = mock.add_file(
      "test.txt",
      content=(
        #|line 1
        #|line 2
        #|line 3
        #|line 4
        #|line 5
        #|line 6
        #|line 7
        #|line 8
        #|line 9
        #|line 10
        #|line 11
        #|line 12
      ),
    )
    let args : Json = { "path": "test.txt" }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content={
      "path": "test.txt",
      "content": "line 1\nline 2\nline 3\nline 4\nline 5\nline 6\nline 7\nline 8\nline 9\nline 10\nline 11\nline 12",
      "start_line": 1,
      "end_line": 12,
    })
    inspect(
      output,
      content=(
        #|File: test.txt (lines 1-12 (12 lines))
        #| L01 | line 1
        #| L02 | line 2
        #| L03 | line 3
        #| L04 | line 4
        #| L05 | line 5
        #| L06 | line 6
        #| L07 | line 7
        #| L08 | line 8
        #| L09 | line 9
        #| L10 | line 10
        #| L11 | line 11
        #| L12 | line 12
      ),
    )
  })
}

///|
async test "line_range" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    let _ = mock.add_file(
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
    @json.inspect(output, content={
      "path": "lines.txt",
      "content": "line 1\nline 2\nline 3\nline 4\nline 5",
      "start_line": 2,
      "end_line": 4,
    })
    inspect(
      output,
      content=(
        #|File: lines.txt (lines 2-4 (3 lines))
        #| L2 | line 2
        #| L3 | line 3
        #| L4 | line 4
      ),
    )
  })
}

///|
async test "directory" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    mock.add_json_tree({
      "file1.txt": "content1",
      "file2.txt": "content2",
      "subdir": { "file3.txt": "content3" },
    })
    let args : Json = { "path": "." }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    guard result is Error(_, s) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(s, content="Error reading file: Path is a directory: .")
  })
}

///|
async test "invalid-range" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    let _ = mock.add_file(
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
    let args : Json = { "path": "test.txt", "start_line": 3, "end_line": 4 }
    let result = new(manager).call(args)
    inspect(
      result,
      content=(
        #|File: test.txt (lines 3-3 (1 lines))
        #| L3 | line 3
      ),
    )
    let args : Json = { "path": "test.txt", "start_line": 4, "end_line": 10 }
    let result = new(manager).call(args)
    inspect(
      result,
      content="Error: start_line (4) must be <= total lines (3), got 4",
    )
    let args : Json = { "path": "test.txt", "start_line": 2, "end_line": 1024 }
    let tool = new(manager)
    let result = tool.call(args)
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content={
      "path": "test.txt",
      "content": "line 1\nline 2\nline 3",
      "start_line": 2,
      "end_line": 3,
    })
    inspect(
      output,
      content=(
        #|File: test.txt (lines 2-3 (2 lines))
        #| L2 | line 2
        #| L3 | line 3
      ),
    )
  })
}
