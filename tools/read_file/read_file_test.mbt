///|
async test "nonexistent" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    let args : Json = { "path": "nonexistent.txt" }
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(
      result.output(),
      content="Error reading file: File not found: nonexistent.txt",
    )
    guard result is Error(error, _) else {
      fail("Expected an error for nonexistent file")
    }
    @json.inspect(error, content=[
      "Failure", "Error reading file: File not found: nonexistent.txt",
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
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(result.output(), content={
      "path": "test.txt",
      "content": "line 1\nline 2\nline 3\nline 4",
      "start_line": 1,
      "end_line": 4,
    })
    inspect(
      (@read_file.read_file.render)(result),
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
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(result.output(), content={
      "path": "lines.txt",
      "content": "line 1\nline 2\nline 3\nline 4\nline 5",
      "start_line": 2,
      "end_line": 4,
    })
    inspect(
      (@read_file.read_file.render)(result),
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
    let _ = taco.add_file("file1.txt", content="content1")
    let _ = taco.add_file("file2.txt", content="content2")
    let subdir = taco.add_directory("subdir")
    let _ = subdir.add_file("file3.txt", content="content3")
    let args : Json = { "path": "." }
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(result.output(), content={
      "path": ".",
      "entries": ["subdir/", "file1.txt", "file2.txt"],
      "display": "subdir/\nfile1.txt\nfile2.txt",
    })
    inspect(
      (@read_file.read_file.render)(result),
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
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(
      result.output(),
      content="Error: end_line (2) must be greater than start_line (3)",
    )
    let args : Json = { "path": "test.txt", "start_line": 0 }
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(
      result.output(),
      content="Error: start_line must be >= 1, got 0",
    )
    let args : Json = { "path": "test.txt", "start_line": 2, "end_line": 1024 }
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(result.output(), content={
      "path": "test.txt",
      "content": "line 1\nline 2\nline 3",
      "start_line": 2,
      "end_line": 3,
    })
    inspect(
      (@read_file.read_file.render)(result),
      content=(
        #|File: test.txt (lines 2-3 (2 lines))
        #|line 2
        #|line 3
      ),
    )
  })
}
