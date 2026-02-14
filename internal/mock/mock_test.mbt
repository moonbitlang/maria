///|
async test "retry" (t : @test.Test) {
  try {
    @mock.run(t, retry=3, _ => assert_false(true))
    fail("should have failed")
  } catch {
    _ => ()
  }
  let mut count = 0
  @mock.run(t, retry=2, _ => {
    count += 1
    if count < 3 {
      fail("fail")
    }
  })
}

///|
async test "moon_home" (t : @test.Test) {
  @mock.run(t, mock => {
    inspect(mock.show(mock.moon_home), content="(mock:env:MOON_HOME)")
  })
}

///|
async test "add_json_tree" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "file.txt": "hello",
      "subdir": {
        "nested.txt": "world",
        "deep": { "a.txt": "aaa", "b.txt": "bbb" },
      },
      "empty_dir": {},
    })
    // Verify root file
    let root_file_path = @pathx.join(mock.cwd.path(), "file.txt")
    inspect(@fs.read_file(root_file_path).text(), content="hello")
    // Verify nested file
    let nested_file_path = @pathx.join(
      @pathx.join(mock.cwd.path(), "subdir"),
      "nested.txt",
    )
    inspect(@fs.read_file(nested_file_path).text(), content="world")
    // Verify deeply nested files
    let deep_dir = @pathx.join(@pathx.join(mock.cwd.path(), "subdir"), "deep")
    let deep_a_path = @pathx.join(deep_dir, "a.txt")
    let deep_b_path = @pathx.join(deep_dir, "b.txt")
    inspect(@fs.read_file(deep_a_path).text(), content="aaa")
    inspect(@fs.read_file(deep_b_path).text(), content="bbb")
    // Verify empty directory exists
    let empty_dir_path = @pathx.join(mock.cwd.path(), "empty_dir")
    inspect(@fs.kind(empty_dir_path) is @fs.FileKind::Directory, content="true")
  })
}

///|
async test "add_json_tree/empty_tree" (t : @test.Test) {
  @mock.run(t, mock => {
    // Empty tree should work without errors
    mock.add_json_tree({})
    let entries = mock.cwd.list()
    inspect(entries.length(), content="0")
  })
}

///|
async test "add_json_tree/empty_content" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({ "empty.txt": "" })
    let file_path = @pathx.join(mock.cwd.path(), "empty.txt")
    inspect(@fs.read_file(file_path).text(), content="")
  })
}

///|
async test "add_json_tree/directory_then_add_more" (t : @test.Test) {
  @mock.run(t, mock => {
    // First add some structure
    mock.add_json_tree({ "dir1": { "a.txt": "a" } })
    // Then add more to the root
    mock.add_json_tree({ "dir2": { "b.txt": "b" } })
    // Verify both exist
    let a_path = @pathx.join(@pathx.join(mock.cwd.path(), "dir1"), "a.txt")
    let b_path = @pathx.join(@pathx.join(mock.cwd.path(), "dir2"), "b.txt")
    inspect(@fs.read_file(a_path).text(), content="a")
    inspect(@fs.read_file(b_path).text(), content="b")
  })
}

///|
async test "add_json_tree/invalid_value_panics" (t : @test.Test) {
  @mock.run(t, mock => {
    try {
      // Number value should cause a panic
      mock.add_json_tree({ "file.txt": Json::number(42) })
      fail("Expected panic for invalid JSON value")
    } catch {
      _ => () // Expected to fail
    }
  })
}

///|
async test "add_json_tree/special_characters_in_filename" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "file with spaces.txt": "content1",
      "file-with-dashes.txt": "content2",
      "file_with_underscores.txt": "content3",
    })
    let p1 = @pathx.join(mock.cwd.path(), "file with spaces.txt")
    let p2 = @pathx.join(mock.cwd.path(), "file-with-dashes.txt")
    let p3 = @pathx.join(mock.cwd.path(), "file_with_underscores.txt")
    inspect(@fs.read_file(p1).text(), content="content1")
    inspect(@fs.read_file(p2).text(), content="content2")
    inspect(@fs.read_file(p3).text(), content="content3")
  })
}
