///|
async test (t : @test.T) {
  @mock.run(t, taco => {
    taco.add_files([
      (
        "moon.mod.json",
        (
          #|{ "name": "example", "version": "0.1.0" }
        ),
      ),
      (
        "moon.pkg.json",
        (
          #|{ }
        ),
      ),
      ("example.mbt", "let x : Int = \"string\""),
    ])
    let diagnostics = check(cwd=taco.cwd.path())
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
