///|
test "read_file/nonexistent" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-read-file-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let args : Json = { "path": "nonexistent.txt" }
    let result = @file.read_file.call(args, manager)
    @json.inspect(
      result.output,
      content="Error reading file: File not found: nonexistent.txt",
    )
    @json.inspect(result.error, content=[
      "moonbitlang/maria/tool.Failure.Failure",
    ])
  })
}

///|
test "read_file/content" {
  @async.with_event_loop(g => {
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
    let result = @file.read_file.call(args, manager)
    inspect(
      result.output,
      content=(
        #|Object({"path": String("test.txt"), "content": String("line 1\nline 2\nline 3\nline 4"), "start_line": Number(1), "end_line": Number(4)})
      ),
    )
  })
}

///|
test "read_file/line_range" {
  @async.with_event_loop(g => {
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
    let result = @file.read_file.call(args, manager)
    inspect(
      result.output,
      content=(
        #|Object({"path": String("lines.txt"), "content": String("line 1\nline 2\nline 3\nline 4\nline 5"), "start_line": Number(2), "end_line": Number(4)})
      ),
    )
  })
}

///|
test "read_file/directory" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-read-file-directory-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let _ = cwd.add_file("file1.txt", "content1")
    let _ = cwd.add_file("file2.txt", "content2")
    let subdir = cwd.add_subdirectory("subdir")
    g.add_defer(() => subdir.close())
    let _ = subdir.add_file("file3.txt", "content3")
    let args : Json = { "path": "." }
    let result = @file.read_file.call(args, manager)
    @json.inspect(result.output, content={
      "type": "directory",
      "path": ".",
      "entries": ["subdir/", "file1.txt", "file2.txt"],
      "display": "subdir/\nfile1.txt\nfile2.txt",
    })
  })
}
