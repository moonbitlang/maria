///|
async test "list_files" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    taco.add_files([
      ("moon.pkg.json", "{}"),
      ("tool.mbt", "// tool"),
      ("tool_test.mbt", "// test"),
    ])
    inspect(
      @list_files.list_files.call({ "path": "." }, manager).output,
      content=(
        #|Directory: .
        #|Total: 3 items (3 files, 0 directories)
        #|
        #|📄 tool.mbt
        #|📄 moon.pkg.json
        #|📄 tool_test.mbt
      ),
    )
  })
}
