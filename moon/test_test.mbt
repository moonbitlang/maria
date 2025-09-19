///|
async test "test" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("moon-test")
    g.add_defer(() => cwd.close())
    let _ = cwd.add_file(
      "moon.mod.json",
      { "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = cwd.add_file("moon.pkg.json", Json::object({}).stringify())
    let _ = cwd.add_file(
      "test.mbt",
      (
        #|///|
        #|test "add" {
        #|  let x = 2 + 2
        #|  @json.inspect(x, content=3)
        #|}
        #|
        #|///|
        #|test "eq" {
        #|  assert_eq(1 + 1, 3)
        #|}
      ),
    )
    let moon = @moon.Module::load(cwd.path())
    moon.check()
    @json.inspect(cwd.strip_cwd(moon.test_()), content=[
      {
        "package_": "example",
        "filename": "test.mbt",
        "index": 0,
        "test_name": "add",
        "message": [
          "ExpectFailed",
          {
            "loc": "./test.mbt:4:3-4:30",
            "args_loc": [
              ["./test.mbt:4:17-4:18"],
              ["./test.mbt:4:28-4:29"],
              null,
              null,
            ],
            "expect": "3",
            "actual": "4",
            "mode": "json",
          },
        ],
      },
      {
        "package_": "example",
        "filename": "test.mbt",
        "index": 1,
        "test_name": "eq",
        "message": ["String", "./test.mbt:9:3-9:22 FAILED: `2 != 3`"],
      },
    ])
  })
}
