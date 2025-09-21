///|
test "write_to_file/create" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-write-file-test")
    g.add_defer(() => cwd.close())
    let manager = manager(cwd.path())
    let args : Json = { "path": "nonexistent.txt" }
    let result = manager
      .get_write_to_file_tool()
      .call(args, @tool.context(model=@mock.model(), cwd=cwd.path()))
    @json.inspect(result, content={
      "output": "New file created and content written to nonexistent.txt",
    })
  })
}

///|
test "write_to_file/replace" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-write-file-test")
    g.add_defer(() => cwd.close())
    let manager = manager(cwd.path())
    let _ = cwd.add_file("file.txt", "Old content")
    let args : Json = {
      "path": "file.txt",
      "search": "Old content",
      "replace": "New content",
    }
    let result = manager
      .get_write_to_file_tool()
      .call(args, @tool.context(model=@mock.model(), cwd=cwd.path()))
    @json.inspect(result, content={ "output": "Changes applied to file.txt" })
  })
}

///|
test "write_to_file/fail-to-match" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-write-file-test")
    g.add_defer(() => cwd.close())
    let manager = manager(cwd.path())
    let _ = cwd.add_file("file.txt", "Old content")
    let args : Json = {
      "path": "file.txt",
      "search": "Non-matching content",
      "replace": "New content",
    }
    let result = manager
      .get_write_to_file_tool()
      .call(args, @tool.context(model=@mock.model(), cwd=cwd.path()))
    @json.inspect(result, content={
      "output": "Search content not found in file (tried all matching strategies): Non-matching content",
      "error": [
        "Failure", "Search content not found in file (tried all matching strategies): Non-matching content",
      ],
    })
  })
}
