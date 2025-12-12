///|
async test "truncate" (t : @test.Test) {
  @mock.run(t, mock => {
    let file_path = @pathx.join(mock.cwd.path(), "test.txt")
    {
      let file = @fs.open(file_path, mode=WriteOnly, create=0o644)
      defer file.close()
      file.write("Hello, World!")
    }
    {
      let file = @fs.open(file_path, mode=ReadWrite)
      defer file.close()
      truncate(file, 5)
      inspect(file.read_all().text(), content="Hello")
    }
    let file = @fs.open(file_path, mode=ReadOnly)
    defer file.close()
    inspect(file.read_all().text(), content="Hello")
  })
}
