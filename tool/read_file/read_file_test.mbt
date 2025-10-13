///|
async test "read_file/nonexistent" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-read-file-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let args : Json = { "path": "nonexistent.txt" }
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(
      result.output,
      content="Error reading file: File not found: nonexistent.txt",
    )
    @json.inspect(result.error, content=[
      ["Failure", "Error reading file: File not found: nonexistent.txt"],
    ])
  })
}

///|
async test "read_file/content" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-read-file-content-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let _ = cwd.add_file(
      "test.txt",
      (
        #|line 1
        #|line 2
        #|line 3
        #|line 4
      ),
    )
    let args : Json = { "path": "test.txt" }
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(result.output, content={
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
async test "read_file/line_range" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-read-file-range-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let _ = cwd.add_file(
      "lines.txt",
      (
        #|line 1
        #|line 2
        #|line 3
        #|line 4
        #|line 5
      ),
    )
    let args : Json = { "path": "lines.txt", "start_line": 2, "end_line": 4 }
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(result.output, content={
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
async test "read_file/directory" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-read-file-directory-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let _ = cwd.add_file("file1.txt", "content1")
    let _ = cwd.add_file("file2.txt", "content2")
    let subdir = cwd.add_directory("subdir")
    g.add_defer(() => subdir.close())
    let _ = subdir.add_file("file3.txt", "content3")
    let args : Json = { "path": "." }
    let result = @read_file.read_file.call(args, manager)
    @json.inspect(result.output, content={
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
async test "read_file/invalid-range" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-read-file-invalid-range-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let _ = cwd.add_file(
      "test.txt",
      (
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
    @json.inspect(result.output, content={
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
