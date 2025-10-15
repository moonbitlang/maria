///|
async test "discover" (t : @test.T) {
  @mock.run(t, taco => {
    let _ = taco.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0", "source": "src" }
        .to_json()
        .stringify(),
    )
    let src = taco.add_directory("src")
    let _ = src.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let src_lib = src.add_directory("lib")
    let _ = src_lib.add_file(
      "moon.pkg.json",
      content=Json::object({}).stringify(),
    )
    let src_lib_util = src_lib.add_directory("util")
    let _ = src_lib_util.add_file(
      "moon.pkg.json",
      content=Json::object({}).stringify(),
    )
    let util = taco.add_directory("util")
    let _ = util.add_file("helpers.mbt", content="let x : Int = 42")
    let src_app = src.add_directory("app")
    let _ = src_app.add_file(
      "moon.pkg.json",
      content=Json::object({}).stringify(),
    )
    let _ = src_app.add_file("main.mbt", content="let y : String = \"hello\"")
    let moon = Module::load(taco.cwd.path())
    moon.discover()
    let pkg_names = moon.packages.keys().collect()
    pkg_names.sort()
    @json.inspect(pkg_names, content=[
      "example", "example/app", "example/lib", "example/lib/util",
    ])
  })
}

///|
async test "diagnostics" (t : @test.T) {
  @mock.run(t, taco => {
    let _ = taco.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = taco.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let _ = taco.add_file("example.mbt", content="let x : Int = \"string\"")
    let moon = Module::load(taco.cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics().collect()
    @json.inspect(taco.json(diagnostics), content=[
      {
        "error_code": 2,
        "level": "Warning",
        "loc": {
          "end": { "col": 6, "line": 1 },
          "path": "(mock:cwd)/example.mbt",
          "start": { "col": 5, "line": 1 },
        },
        "message": "Warning: Unused variable 'x'",
      },
      {
        "error_code": 4014,
        "level": "Error",
        "loc": {
          "end": { "col": 23, "line": 1 },
          "path": "(mock:cwd)/example.mbt",
          "start": { "col": 15, "line": 1 },
        },
        "message": "Expr Type Mismatch\n        has type : String\n        wanted   : Int",
      },
    ])
  })
}
