///|
async test "check_moonbit_project" (t : @test.T) {
  @mock.run(t, taco => {
    taco.add_files([
      (
        "moon.mod.json",
        { "name": "example", "version": "0.1.0" }.to_json().stringify(),
      ),
      ("moon.pkg.json", Json::object({}).stringify()),
      (
        "example.mbt",
        (
          #|///|
          #|let x : Int = "string"
        ),
      ),
    ])
    let args = input_json(diagnostic_limit=10, project_path=taco.cwd.path())
    let result = new(taco.cwd.path()).call(args)
    @json.inspect(taco.json(result), content=[
      "Ok",
      {
        "diagnostics": [
          {
            "error_code": 2,
            "level": "Warning",
            "loc": {
              "end": { "col": 6, "line": 2 },
              "path": "(mock:cwd)/example.mbt",
              "start": { "col": 5, "line": 2 },
            },
            "message": "Warning: Unused variable 'x'",
          },
          {
            "error_code": 4014,
            "level": "Error",
            "loc": {
              "end": { "col": 23, "line": 2 },
              "path": "(mock:cwd)/example.mbt",
              "start": { "col": 15, "line": 2 },
            },
            "message": "Expr Type Mismatch\n        has type : String\n        wanted   : Int",
          },
        ],
        "diagnostic_limit": 10,
        "rendered_diagnostics": "MoonBit project check found the following diagnostics:\n\nwarning[0002]: (mock:cwd)/example.mbt: Warning: Unused variable 'x'\n 2 │ let x : Int = \"string\"\n   │     ^\n\nerror[4014]: (mock:cwd)/example.mbt: Expr Type Mismatch\n        has type : String\n        wanted   : Int\n 2 │ let x : Int = \"string\"\n   │               ^^^^^^^^\n\nThere are 1 more error(s) and 1 more warning(s) not shown due to diagnostic limit.",
      },
    ])
    inspect(
      taco.show(result),
      content=(
        #|MoonBit project check found the following diagnostics:
        #|
        #|warning[0002]: (mock:cwd)/example.mbt: Warning: Unused variable 'x'
        #| 2 │ let x : Int = "string"
        #|   │     ^
        #|
        #|error[4014]: (mock:cwd)/example.mbt: Expr Type Mismatch
        #|        has type : String
        #|        wanted   : Int
        #| 2 │ let x : Int = "string"
        #|   │               ^^^^^^^^
        #|
        #|There are 1 more error(s) and 1 more warning(s) not shown due to diagnostic limit.
      ),
    )
  })
}

///|
async test "check_moonbit_project/patch-insert" (t : @test.T) {
  @mock.run(t, taco => {
    taco.add_files([
      (
        "moon.mod.json",
        { "name": "example", "version": "0.1.0" }.to_json().stringify(),
      ),
      ("moon.pkg.json", Json::object({}).stringify()),
      (
        "example.mbt",
        (
          #|///|
          #|let x : Int = "string"
          #|
        ),
      ),
    ])
    let args = input_json(
      diagnostic_limit=10,
      project_path=taco.cwd.path(),
      patch_code="let y : String = 42",
      patch_file_name="example.mbt",
    )
    let result = new(taco.cwd.path()).call(args)

    // Note we don't really change the file
    inspect(
      @fs.read_file(@path.join(taco.cwd.path(), "example.mbt")),
      content=(
        #|///|
        #|let x : Int = "string"
        #|
      ),
    )
    @json.inspect(taco.json(result), content=[
      "Ok",
      {
        "diagnostics": [
          {
            "error_code": 2,
            "level": "Warning",
            "loc": {
              "end": { "col": 6, "line": 1 },
              "path": "(mock:cwd)/example.mbt",
              "start": { "col": 5, "line": 1 },
            },
            "message": "Warning: Unused variable 'y'",
          },
          {
            "error_code": 4014,
            "level": "Error",
            "loc": {
              "end": { "col": 20, "line": 1 },
              "path": "(mock:cwd)/example.mbt",
              "start": { "col": 18, "line": 1 },
            },
            "message": "Expr Type Mismatch\n        has type : Int\n        wanted   : String",
          },
        ],
        "diagnostic_limit": 10,
        "rendered_diagnostics": "MoonBit project check found the following diagnostics:\n\nwarning[0002]: (mock:cwd)/example.mbt: Warning: Unused variable 'y'\n 1 │ ///|\n   │     ^\n\nerror[4014]: (mock:cwd)/example.mbt: Expr Type Mismatch\n        has type : Int\n        wanted   : String\n 1 │ ///|\n   │                  ^^\n\nThere are 1 more error(s) and 1 more warning(s) not shown due to diagnostic limit.",
      },
    ])
    inspect(
      taco.show(result),
      content=(
        #|MoonBit project check found the following diagnostics:
        #|
        #|warning[0002]: (mock:cwd)/example.mbt: Warning: Unused variable 'y'
        #| 1 │ ///|
        #|   │     ^
        #|
        #|error[4014]: (mock:cwd)/example.mbt: Expr Type Mismatch
        #|        has type : Int
        #|        wanted   : String
        #| 1 │ ///|
        #|   │                  ^^
        #|
        #|There are 1 more error(s) and 1 more warning(s) not shown due to diagnostic limit.
      ),
    )
  })
}
