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
    let write_to_file = manager.get_write_to_file_tool()
    let read_file = manager.get_read_file_tool()
    @json.inspect(
      read_file.call(
        { "path": "file.txt" },
        @tool.context(model=@mock.model(), cwd=cwd.path()),
      ),
      content={
        "output": (
          #|File: file.txt (lines 1-1 (1 lines))
          #|Old content
        ),
      },
    )
    let args : Json = {
      "path": "file.txt",
      "search": "Old content",
      "replace": "New content",
    }
    let result = write_to_file.call(
      args,
      @tool.context(model=@mock.model(), cwd=cwd.path()),
    )
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

///|
test "write_to_file/search-replace" {
  @async.with_event_loop(g => {
    let cwd = @mock.directory("tool-write-file-test")
    g.add_defer(() => cwd.close())
    let manager = manager(cwd.path())
    let _ = cwd.add_file(
      "file.txt",
      (
        #|line 1
        #|line 2
        #|line 3
        #|line 4
      ),
    )
    let write_to_file = manager.get_write_to_file_tool()
    let args : Json = {
      "path": "file.txt",
      "search": "line 2",
      "replace": "line 2 modified",
    }
    let result = write_to_file.call(
      args,
      @tool.context(model=@mock.model(), cwd=cwd.path()),
    )
    @json.inspect(result, content={ "output": "Changes applied to file.txt" })
  })
}
