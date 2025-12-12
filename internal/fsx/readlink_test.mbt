///|
async test "readlink" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_file("source.txt").write_string("Hello, World!")
    mock.add_symlink("link.txt", to="source.txt")
    @json.inspect(
      @fsx.read_file(@pathx.join(mock.cwd.path(), "link.txt")),
      content="Hello, World!",
    )
    @json.inspect(
      @fsx.readlink(@pathx.join(mock.cwd.path(), "link.txt")),
      content="source.txt",
    )
    @json.inspect(
      @fsx.readlink(@pathx.join(mock.cwd.path(), "link.txt"), bufsize=2),
      content="source.txt",
    )
    @json.inspect(
      (try? @fsx.readlink(@pathx.join(mock.cwd.path(), "nonexistent")))
      is Err(@errno.Errno(errno)) &&
      errno == @errno.enoent,
      content=true,
    )
    @json.inspect(
      (try? @fsx.readlink(@pathx.join(mock.cwd.path(), "source.txt")))
      is Err(@errno.Errno(errno)) &&
      errno == @errno.einval,
      content=true,
    )
  })
}
