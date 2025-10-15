///|
async test "append_to_file" (t : @test.T) {
  @mock.run(t, taco => {
    @fs.write_to_file(
      @path.join(taco.cwd.path(), "file.txt"),
      "Line 1\nLine 2\n",
    )
    let args = @append_to_file.params(
      path="file.txt",
      content="Line 3",
      separator="\n",
    )
    let result = @append_to_file.append_to_file.call(
      args.to_json(),
      taco.cwd.path(),
    )
    @json.inspect(taco.json(result.output), content={ "path": "./file.txt" })
    let final_content = @fs.read_file(@path.join(taco.cwd.path(), "file.txt"))
    @json.inspect(final_content, content="Line 1\nLine 2\n\nLine 3")
  })
}
