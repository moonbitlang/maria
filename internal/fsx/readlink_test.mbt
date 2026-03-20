///|
async test "readlink" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_file("source.txt").write_string("Hello, World!")
    mock.add_symlink("link.txt", to="source.txt")
    json_inspect(
      @fsx.read_file(Path::join(mock.cwd.path(), "link.txt").to_string()),
      content="Hello, World!",
    )
    json_inspect(
      @fsx.readlink(Path::join(mock.cwd.path(), "link.txt").to_string()),
      content="source.txt",
    )
    json_inspect(
      @fsx.readlink(
        Path::join(mock.cwd.path(), "link.txt").to_string(),
        bufsize=2,
      ),
      content="source.txt",
    )
    json_inspect(
      (try? @fsx.readlink(
        Path::join(mock.cwd.path(), "nonexistent").to_string(),
      ))
      is Err(@errno.Errno(errno)) &&
      errno == @errno.enoent,
      content=true,
    )
    json_inspect(
      (try? @fsx.readlink(Path::join(mock.cwd.path(), "source.txt").to_string()))
      is Err(@errno.Errno(errno)) &&
      errno == @errno.einval,
      content=true,
    )
  })
}
