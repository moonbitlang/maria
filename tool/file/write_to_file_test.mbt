///|
async test "write_to_file/create" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-write-file-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let args : Json = { "path": "nonexistent.txt" }
    let result = @file.write_to_file.call(args, manager)
    @json.inspect(result, content={
      "output": "New file created and content written to nonexistent.txt",
    })
  })
}

///|
async test "write_to_file/replace" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-write-file-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let _ = cwd.add_file("file.txt", "Old content")
    @json.inspect(@file.read_file.call({ "path": "file.txt" }, manager), content={
      "output": (
        #|File: file.txt (lines 1-1 (1 lines))
        #|Old content
      ),
    })
    let args : Json = {
      "path": "file.txt",
      "search": "Old content",
      "replace": "New content",
    }
    let result = @file.write_to_file.call(args, manager)
    @json.inspect(result, content={ "output": "Changes applied to file.txt" })
  })
}

///|
async test "write_to_file/fail-to-match" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-write-file-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let _ = cwd.add_file("file.txt", "Old content")
    let args : Json = {
      "path": "file.txt",
      "search": "Non-matching content",
      "replace": "New content",
    }
    let result = @file.write_to_file.call(args, manager)
    @json.inspect(result, content={
      "output": "Search content not found in file (tried all matching strategies): Non-matching content",
      "error": [
        "Failure", "Search content not found in file (tried all matching strategies): Non-matching content",
      ],
    })
  })
}

///|
async test "write_to_file/search-replace" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("tool-write-file-test")
    g.add_defer(() => cwd.close())
    let manager = @file.manager(cwd=cwd.path())
    let _ = cwd.add_file(
      "file.txt",
      (
        #|line 1
        #|line 2
        #|line 3
        #|line 4
      ),
    )
    let args : Json = {
      "path": "file.txt",
      "search": "line 2",
      "replace": "line 2 modified",
    }
    let result = @file.write_to_file.call(args, manager)
    @json.inspect(result, content={ "output": "Changes applied to file.txt" })
  })
}
