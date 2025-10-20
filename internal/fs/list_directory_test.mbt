///|
async test "list_directory" (t : @test.T) {
  @mock.run(t, taco => {
    taco.add_files([("file1.txt", "content1"), ("file2.txt", "content2")])
    let subdir = taco.add_directory("subdir")
    let _ = subdir.add_file("file3.txt", content="content3")
    @json.inspect(taco.json(@this.list_directory(taco.cwd.path())), content=[
      { "path": "(mock:cwd)/subdir", "name": "subdir", "kind": "Directory" },
      { "path": "(mock:cwd)/file1.txt", "name": "file1.txt", "kind": "Regular" },
      { "path": "(mock:cwd)/file2.txt", "name": "file2.txt", "kind": "Regular" },
    ])
  })
}
