///|
async test "test" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
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
            "loc": {
              "pkg": "example",
              "filename": "test.mbt",
              "start_line": 4,
              "start_column": 3,
              "end_line": 4,
              "end_column": 30,
            },
            "args_loc": [
              [
                {
                  "pkg": "example",
                  "filename": "test.mbt",
                  "start_line": 4,
                  "start_column": 17,
                  "end_line": 4,
                  "end_column": 18,
                },
              ],
              [
                {
                  "pkg": "example",
                  "filename": "test.mbt",
                  "start_line": 4,
                  "start_column": 28,
                  "end_line": 4,
                  "end_column": 29,
                },
              ],
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
        "message": ["String", "test.mbt:9:3-9:22@example FAILED: `2 != 3`"],
      },
    ])
  })
}
