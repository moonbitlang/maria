///|
test "read_file/nonexistent" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-read-file-test")
    g.add_defer(() => cwd.close())
    let args : Json = { "path": "nonexistent.txt" }
    let result = @read_file.read_file.call(args, @tool.context(cwd=cwd.path()))
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
    let result = @read_file.read_file.call(args, @tool.context(cwd=cwd.path()))
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
    let result = @read_file.read_file.call(args, @tool.context(cwd=cwd.path()))
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
