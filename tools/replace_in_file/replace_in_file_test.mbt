///|
using @path {type Path}

///|
async test "replace_in_file/create" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    let args : Json = { "path": "nonexistent.txt" }
    let result = @replace_in_file.new(manager).call(args)
    json_inspect(result, content=[
      "Failed",
      [
        "ToolFailure", "Error: Invalid arguments provided to replace_in_file tool: JsonDecodeError((, Missing field replace))",
      ],
    ])
  })
}

///|
async test "replace_in_file/replace" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    mock.add_json_tree({ "file.txt": "Old content" })
    json_inspect(@read_file.new(manager).call({ "path": "file.txt" }), content=[
      "Success", "File: file.txt (lines 1-1 (1 lines))\n L1 | Old content",
    ])
    let args : Json = {
      "path": "file.txt",
      "search": "",
      "replace": "New content",
    }
    let result = @replace_in_file.new(manager).call(args)
    json_inspect(result, content=["Success", "Changes applied to file.txt"])
  })
}

///|
async test "replace_in_file/search-is-required" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    mock.add_json_tree({ "file.txt": "Old content" })
    let args : Json = { "path": "file.txt", "replace": "New content" }
    let result = @replace_in_file.new(manager).call(args)
    json_inspect(result, content=["Success", "Changes applied to file.txt"])
    guard result is Success(result) else { fail("Expected Ok result") }
    inspect(
      result.to_message().content(),
      content="Changes applied to file.txt",
    )
  })
}

///|
async test "replace_in_file/fail-to-match" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    mock.add_json_tree({ "file.txt": "Old content" })
    let args : Json = {
      "path": "file.txt",
      "search": "Non-matching content",
      "replace": "New content",
    }
    let result = @replace_in_file.new(manager).call(args)
    inspect(
      result,
      content=(
        #|Search content not found in file (tried all matching strategies)
        #|
        #|```
        #|Non-matching content
        #|```
        #|
        #|File content:
        #|
        #|```
        #|Old content
        #|```
      ),
    )
  })
}

///|
async test "replace_in_file/search-replace" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    mock.add_json_tree({
      "file.txt": (
        #|line 1
        #|line 2
        #|line 3
        #|line 4
      ),
    })
    let args : Json = {
      "path": "file.txt",
      "search": "line 2",
      "replace": "line 2 modified",
    }
    let result = @replace_in_file.new(manager).call(args)
    json_inspect(result, content=["Success", "Changes applied to file.txt"])
  })
}

///|
/// does not make sense to test render separately as it's just returning the error message
// async test "replace_in_file/render" {
//   json_inspect(
//     (@replace_in_file.new("").render)(@tool.error("Some error occurred")),
//     content="Some error occurred",
//   )
// }

///|
async test "replace_in_file/no-write-permission" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @file.manager(cwd=mock.cwd.path())
    mock.add_json_tree({ "file.txt": "Old content" })
    let file_path = Path::join(mock.cwd.path(), "file.txt").to_string()
    // Change file to read-only
    @fs.chmod(file_path, 0o444)
    let args : Json = {
      "path": "file.txt",
      "search": "",
      "replace": "New content",
    }
    let result = @replace_in_file.new(manager).call(args)
    // Verify that an error is returned
    guard result is Failed(_) else {
      fail("Expected Error result but got: \{result}")
    }
    inspect(
      mock.text(result),
      content="Permission denied: Cannot write to file file.txt. The file does not have write permissions.",
    )
    // Restore write permission for cleanup
    @fs.chmod(file_path, 0o644)
  })
}
