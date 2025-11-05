///|
async test "write_to_file" (t : @test.Test) {
  @mock.run(t, taco => {
    let file = taco.add_file("example.txt", content="")
    @this.write_to_file(file.path(), "Hello, Moonbit!")
    let content = @this.read_file(file.path())
    @json.inspect(content, content="Hello, Moonbit!")
  })
}
