///|
async test "info" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("moon-module")
    g.add_defer(() => cwd.close())
    let _ = cwd.add_file(
      "moon.mod.json",
      { "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = cwd.add_file("moon.pkg.json", Json::object({}).stringify())
    let _ = cwd.add_file("example.mbt", "///|\nlet x : Int = 42")
    info(cwd=cwd.path())
  })
}
