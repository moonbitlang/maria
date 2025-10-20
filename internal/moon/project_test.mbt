///|
async test "project" (t : @test.T) {
  @mock.run(t, mock => {
    let _ = mock.add_file(
      "moon.mod.json",
      content=Json::object({
        "name": "example",
        "deps": { "moonbitlang/async": "0.10.0" },
        "version": "0.1.0",
      }).stringify(),
    )
    let _ = mock.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let _ = mock.add_file("example.mbt", content="///|\nlet x : Int = 42")
    let internal = mock.add_directory("internal")
    let _ = internal.add_file(
      "moon.pkg.json",
      content=Json::object({}).stringify(),
    )
    let _ = internal.add_file(
      "internal.mbt",
      content="///|\nlet value : Int = 37",
    )
    let deps = mock.add_directory("deps")
    let _ = deps.add_file(
      "moon.mod.json",
      content={ "name": "example-deps", "version": "0.1.0" }
        .to_json()
        .stringify(),
    )
    let _ = mock.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let project = @moon.Module::load(mock.cwd.path())
    let mod_names : Array[(String, Array[String])] = []
    @json.inspect(project.name(), content="example")
    for mod in project.modules() {
      mod_names.push(
        (mod.name, mod.packages().map(pkg => pkg.name()).collect()),
      )
    }
    @json.inspect(mod_names, content=[
      ["example", ["example", "example/internal"]],
      ["example-deps", ["example-deps"]],
    ])
    @json.inspect(project.find_module("non-existent") is None, content=true)
    let internal_package = project.find_package("example/internal")
    @json.inspect(mock.json(internal_package), content=[
      {
        "name": "example/internal",
        "path": "(mock:cwd)/internal",
        "files": {
          "(mock:cwd)/internal/internal.mbt": {
            "content": "///|\nlet value : Int = 37",
            "header": { "start": 0, "end": 0, "diagnostics": [] },
            "segments": [{ "start": 0, "end": 2, "diagnostics": [] }],
            "diagnostics": [],
          },
        },
      },
    ])
    project.install()
    @json.inspect(
      project.find_package("moonbitlang/async/pipe") is Some(_),
      content=true,
    )
  })
}
