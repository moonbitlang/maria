///|
async test "list_directory" (t : @test.T) {
  @taco.run(t, taco => {
    let _ = taco.add_file("file1.txt", content="content1")
    let _ = taco.add_file("file2.txt", content="content2")
    let subdir = taco.add_directory("subdir")
    let _ = subdir.add_file("file3.txt", content="content3")
    @json.inspect(taco.json(@this.list_directory(taco.cwd.path())), content=[
      { "path": "./subdir", "name": "subdir", "kind": "Directory" },
      { "path": "./file1.txt", "name": "file1.txt", "kind": "Regular" },
      { "path": "./file2.txt", "name": "file2.txt", "kind": "Regular" },
    ])
  })
}
