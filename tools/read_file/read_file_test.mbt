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
        #|     | line 2
        #|     | line 3
        #|     | line 4
        #|     | line 5
        #|     | line 6
        #|     | line 7
        #|     | line 8
        #|     | line 9
        #|     | line 10
        #| L11 | line 11
        #|     | line 12
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
        #|    | line 3
        #|    | line 4
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
        #|    | line 3
      ),
    )
  })
}

///|
async test "readonly-dont-edit" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    let _ = mock.add_file(
      "readonly.txt",
      content=(
        #|DON'T EDIT
        #|line 2
        #|line 3
        #|line 4
      ),
    )
    let args : Json = { "path": "readonly.txt" }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    inspect(
      result,
      content="Error reading file: This file should be treated as readonly. It contains a readonly marker in the first 3 lines.",
    )
  })
}

///|
async test "readonly-dont-edit-it" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    let _ = mock.add_file(
      "readonly.txt",
      content=(
        #|line 1
        #|DON'T EDIT IT
        #|line 3
        #|line 4
      ),
    )
    let args : Json = { "path": "readonly.txt" }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    inspect(
      result,
      content="Error reading file: This file should be treated as readonly. It contains a readonly marker in the first 3 lines.",
    )
  })
}

///|
async test "readonly-readonly" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    let _ = mock.add_file(
      "readonly.txt",
      content=(
        #|line 1
        #|line 2
        #|READONLY
        #|line 4
      ),
    )
    let args : Json = { "path": "readonly.txt" }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    inspect(
      result,
      content="Error reading file: This file should be treated as readonly. It contains a readonly marker in the first 3 lines.",
    )
  })
}

///|
async test "readonly-read-only" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    let _ = mock.add_file(
      "readonly.txt",
      content=(
        #|line 1
        #|READ ONLY
        #|line 3
        #|line 4
      ),
    )
    let args : Json = { "path": "readonly.txt" }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    inspect(
      result,
      content="Error reading file: This file should be treated as readonly. It contains a readonly marker in the first 3 lines.",
    )
  })
}

///|
async test "readonly-no-edit" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    let _ = mock.add_file(
      "readonly.txt",
      content=(
        #|line 1
        #|line 2
        #|NO EDIT
        #|line 4
      ),
    )
    let args : Json = { "path": "readonly.txt" }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    inspect(
      result,
      content="Error reading file: This file should be treated as readonly. It contains a readonly marker in the first 3 lines.",
    )
  })
}

///|
async test "readonly-case-insensitive" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    let _ = mock.add_file(
      "readonly.txt",
      content=(
        #|line 1
        #|readonly
        #|line 3
        #|line 4
      ),
    )
    let args : Json = { "path": "readonly.txt" }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    inspect(
      result,
      content="Error reading file: This file should be treated as readonly. It contains a readonly marker in the first 3 lines.",
    )
  })
}

///|
async test "readonly-after-3-lines" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    let _ = mock.add_file(
      "editable.txt",
      content=(
        #|line 1
        #|line 2
        #|line 3
        #|readonly
        #|line 5
      ),
    )
    let args : Json = { "path": "editable.txt" }
    let tool = @read_file.new(manager)
    let result = tool.call(args)
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(output, content={
      "path": "editable.txt",
      "content": "line 1\nline 2\nline 3\nreadonly\nline 5",
      "start_line": 1,
      "end_line": 5,
    })
  })
}
