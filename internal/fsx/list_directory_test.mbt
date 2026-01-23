///|
async test "list_directory" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "file1.txt": "content1",
      "file2.txt": "content2",
      "subdir": { "file3.txt": "content3" },
    })
    json_inspect(mock.json(@fsx.list_directory(mock.cwd.path())), content=[
      { "path": "(mock:cwd)/subdir", "name": "subdir", "kind": "Directory" },
      { "path": "(mock:cwd)/file1.txt", "name": "file1.txt", "kind": "Regular" },
      { "path": "(mock:cwd)/file2.txt", "name": "file2.txt", "kind": "Regular" },
    ])
  })
}

///|
async test "should_handle_symlink_when_listing_directory" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({ "file1.txt": "content1" })
    mock.add_symlink("link_to_file1.txt", to="file1.txt")
    mock.add_symlink("link_to_file.txt", to="file.txt")
    json_inspect(mock.json(@fsx.list_directory(mock.cwd.path())), content=[
      { "path": "(mock:cwd)/file1.txt", "name": "file1.txt", "kind": "Regular" },
      {
        "path": "(mock:cwd)/link_to_file.txt",
        "name": "link_to_file.txt",
        "kind": "SymLink",
      },
      {
        "path": "(mock:cwd)/link_to_file1.txt",
        "name": "link_to_file1.txt",
        "kind": "SymLink",
      },
    ])
  })
}
