///|
test "list_directory" {
  @async.with_event_loop(g => {
    let dir = @mock.directory("fs-list_directory")
    g.add_defer(() => dir.close())
    let _ = dir.add_file("file1.txt", "content1")
    let _ = dir.add_file("file2.txt", "content2")
    let _ = dir.with_subdirectory("subdir", subdir => subdir.add_file(
        "file3.txt", "content3",
      )
      |> ignore())
    @json.inspect(dir.list(), content=["subdir/", "file1.txt", "file2.txt"])
  })
}
