///|
let original =
  #|Line 1
  #|Line 2

///|
async test "write_to_file" (t : @test.T) {
  @mock.run(t, taco => {
    @fs.write_to_file(@path.join(taco.cwd.path(), "file.txt"), original)
    let args = json_input(path="file.txt", content="Line 3", separator="\n")
    let tool = new(taco.cwd.path())
    let result = tool.call(args)
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(taco.json(output), content={
      "path": "(mock:cwd)/file.txt",
    })
    let final_content = @fs.read_file(@path.join(taco.cwd.path(), "file.txt"))
    inspect(
      final_content,
      content=(
        #|Line 1
        #|Line 2
        #|Line 3
      ),
    )
  })
}
