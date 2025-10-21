///|
async test "nonexistent" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    let args : Json = { "path": "nonexistent.txt" }
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(
      result.output,
      content="Error reading file: File not found: nonexistent.txt",
    )
    @json.inspect(result.failed, content=[
      ["Failure", "Error reading file: File not found: nonexistent.txt"],
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
    @json.inspect(
      result.output,
      content="File: test.txt (lines 1-4 (4 lines))\nline 1\nline 2\nline 3\nline 4",
    )
    inspect(
      result.output,
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
    @json.inspect(
      result.output,
      content="File: lines.txt (lines 2-4 (3 lines))\nline 2\nline 3\nline 4",
    )
    inspect(
      result.output,
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
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(
      result.output,
      content="Directory: .\nEntries:\nsubdir/\nfile1.txt\nfile2.txt",
    )
    inspect(
      result.output,
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
      result.output,
      content="Error: end_line (2) must be greater than start_line (3)",
    )
    let args : Json = { "path": "test.txt", "start_line": 0 }
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(
      result.output,
      content="Error: start_line must be >= 1, got 0",
    )
    let args : Json = { "path": "test.txt", "start_line": 2, "end_line": 1024 }
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(
      result.output,
      content="File: test.txt (lines 2-3 (2 lines))\nline 2\nline 3",
    )
    inspect(
      result.output,
      content=(
        #|File: test.txt (lines 2-3 (2 lines))
        #|line 2
        #|line 3
      ),
    )
  })
}
