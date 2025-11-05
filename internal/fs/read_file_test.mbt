///|
async test "read_file" (t : @test.Test) {
  @mock.run(t, taco => {
    let file = taco.add_file("example.txt", content="Hello, Moonbit!")
    let content = @this.read_file(file.path())
    @json.inspect(content, content="Hello, Moonbit!")
  })
}
