///|
async test "list_directory" {
  @async.with_task_group(g => {
    let dir = @mock.directory("fs-list_directory")
    g.add_defer(() => dir.close())
    let _ = dir.add_file("file1.txt", "content1")
    let _ = dir.add_file("file2.txt", "content2")
    let subdir = dir.add_directory("subdir")
    let _ = subdir.add_file("file3.txt", "content3")
    @json.inspect(dir.strip_cwd(@this.list_directory(dir.path())), content=[
      { "path": "./subdir", "name": "subdir", "kind": "Directory" },
      { "path": "./file1.txt", "name": "file1.txt", "kind": "Regular" },
      { "path": "./file2.txt", "name": "file2.txt", "kind": "Regular" },
    ])
  })
}
