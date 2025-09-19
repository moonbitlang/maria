///|
async test {
  @async.with_task_group(g => {
    let cwd = @mock.directory("moon-check")
    g.add_defer(() => cwd.close())
    let _ = cwd.add_file(
      "moon.mod.json",
      { "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = cwd.add_file("moon.pkg.json", Json::object({}).stringify())
    let _ = cwd.add_file("example.mbt", "let x : Int = \"string\"")
    let diagnostics = check(cwd=cwd.path())
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
