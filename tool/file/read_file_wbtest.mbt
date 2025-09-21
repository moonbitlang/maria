///|
test "read_file/nonexistent" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-read-file-test")
    g.add_defer(() => cwd.close())
    let manager = manager(cwd.path())
    let args : Json = { "path": "nonexistent.txt" }
    let result = manager
      .get_read_file_tool()
      .call(args, @tool.context(model=@mock.model(), cwd=cwd.path()))
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
test "read_file/content" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-read-file-content-test")
    g.add_defer(() => cwd.close())
    let manager = manager(cwd.path())
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
    let result = manager
      .get_read_file_tool()
      .call(args, @tool.context(model=@mock.model(), cwd=cwd.path()))
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
test "read_file/line_range" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-read-file-range-test")
    g.add_defer(() => cwd.close())
    let manager = manager(cwd.path())
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
    let result = manager
      .get_read_file_tool()
      .call(args, @tool.context(model=@mock.model(), cwd=cwd.path()))
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
test "read_file/directory" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-read-file-directory-test")
    g.add_defer(() => cwd.close())
    let manager = manager(cwd.path())
    let _ = cwd.add_file("file1.txt", "content1")
    let _ = cwd.add_file("file2.txt", "content2")
    let subdir = cwd.add_subdirectory("subdir")
    g.add_defer(() => subdir.close())
    let _ = subdir.add_file("file3.txt", "content3")
    let args : Json = { "path": "." }
    let result = manager
      .get_read_file_tool()
      .call(args, @tool.context(model=@mock.model(), cwd=cwd.path()))
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
