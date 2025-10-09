///|
async test "append_to_file" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("moon-append-to-file")
    g.add_defer(() => cwd.close())
    @fs.write_to_file(@path.join(cwd.path(), "file.txt"), "Line 1\nLine 2\n")
    let args = @append_to_file.params(
      path="file.txt",
      content="Line 3",
      separator="\n",
    )
    let result = @append_to_file.append_to_file.call(args.to_json(), cwd.path())
    @json.inspect(cwd.strip_cwd(result.output), content={ "path": "./file.txt" })
    let final_content = @fs.read_file(@path.join(cwd.path(), "file.txt"))
    @json.inspect(final_content, content="Line 1\nLine 2\n\nLine 3")
  })
}
