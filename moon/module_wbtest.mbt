///|
async test "discover" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("moon-module-discover")
    g.add_defer(() => cwd.close())
    let _ = cwd.add_file(
      "moon.mod.json",
      { "name": "example", "version": "0.1.0", "source": "src" }
      .to_json()
      .stringify(),
    )
    let _ = cwd.add_file("src/moon.pkg.json", Json::object({}).stringify())
    let _ = cwd.add_file("src/lib/moon.pkg.json", Json::object({}).stringify())
    let _ = cwd.add_file(
      "src/lib/util/moon.pkg.json",
      Json::object({}).stringify(),
    )
    let _ = cwd.add_file("src/lib/util/helpers.mbt", "let x : Int = 42")
    let _ = cwd.add_file("src/app/moon.pkg.json", Json::object({}).stringify())
    let _ = cwd.add_file("src/app/main.mbt", "let y : String = \"hello\"")
    let moon = Module::load(cwd.path())
    moon.discover()
    let pkg_names = moon.packages.keys().collect()
    pkg_names.sort()
    @json.inspect(pkg_names, content=[
      "example", "example/app", "example/lib", "example/lib/util",
    ])
  })
}

///|
async test "diagnostics" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("moon-check")
    g.add_defer(() => cwd.close())
    let _ = cwd.add_file(
      "moon.mod.json",
      { "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = cwd.add_file("moon.pkg.json", Json::object({}).stringify())
    let _ = cwd.add_file("example.mbt", "let x : Int = \"string\"")
    let moon = Module::load(cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics().collect()
    @json.inspect(cwd.strip_cwd(diagnostics), content=[
      {
        "error_code": 2,
        "level": "Warning",
        "loc": {
          "end": { "col": 6, "line": 1 },
          "path": "./example.mbt",
          "start": { "col": 5, "line": 1 },
        },
        "message": "Warning: Unused variable 'x'",
      },
      {
        "error_code": 4014,
        "level": "Error",
        "loc": {
          "end": { "col": 23, "line": 1 },
          "path": "./example.mbt",
          "start": { "col": 15, "line": 1 },
        },
        "message": "Expr Type Mismatch\n        has type : String\n        wanted   : Int",
      },
    ])
  })
}
