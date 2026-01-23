///|
async test "project" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "moon.mod.json": Json::object({
        "name": "example",
        "deps": { "moonbitlang/async": "0.10.0" },
        "version": "0.1.0",
      }).stringify(),
      "moon.pkg.json": Json::object({}).stringify(),
      "example.mbt": "///|\nlet x : Int = 42",
      "internal": {
        "moon.pkg.json": Json::object({}).stringify(),
        "internal.mbt": "///|\nlet value : Int = 37",
      },
      "deps": {
        "moon.mod.json": { "name": "example-deps", "version": "0.1.0" }
        .to_json()
        .stringify(),
        "moon.pkg.json": Json::object({}).stringify(),
      },
    })
    let project = @moon.Module::load(mock.cwd.path())
    json_inspect(project.name, content="example")
    let internal_package = project.find_package("example/internal")
    json_inspect(mock.json(internal_package), content=[
      {
        "name": "example/internal",
        "path": "(mock:cwd)/internal",
        "files": {
          "(mock:cwd)/internal/internal.mbt": {
            "content": "///|\nlet value : Int = 37",
            "header": {
              "start": 0,
              "end": 0,
              "diagnostics": ["Diagnostics", []],
            },
            "segments": [
              { "start": 0, "end": 2, "diagnostics": ["Diagnostics", []] },
            ],
            "diagnostics": ["Diagnostics", []],
          },
        },
      },
    ])
    project.install()
    json_inspect(
      project.find_package("moonbitlang/async/pipe") is Some(_),
      content=true,
    )
  })
}
