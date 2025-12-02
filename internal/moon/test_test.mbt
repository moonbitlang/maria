///|
async test "test" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_files({
      "moon.mod.json": (
        #|{ "name": "example", "version": "0.1.0" }
      ),
      "moon.pkg.json": (
        #|{ }
      ),
      "test.mbt": (
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
    })
    let moon = @moon.Module::load(mock.cwd.path())
    moon.check()
    @json.inspect(mock.json(moon.test_()), content=[
      {
        "package_": "example",
        "filename": "test.mbt",
        "index": 0,
        "test_name": "add",
        "message": [
          "ExpectFailed",
          {
            "loc": "(mock:cwd)/test.mbt:4:3-4:30",
            "args_loc": [
              ["(mock:cwd)/test.mbt:4:17-4:18"],
              ["(mock:cwd)/test.mbt:4:28-4:29"],
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
        "message": ["String", "(mock:cwd)/test.mbt:9:3-9:22 FAILED: `2 != 3`"],
      },
    ])
  })
}
