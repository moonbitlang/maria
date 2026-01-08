///|
async test "check_moonbit_project" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "moon.mod.json": { "name": "example", "version": "0.1.0" }
      .to_json()
      .stringify(),
      "moon.pkg.json": Json::object({}).stringify(),
      "example.mbt": (
        #|///|
        #|let x : Int = "string"
      ),
    })
    let args = input_json(diagnostic_limit=10, project_path=mock.cwd.path())
    let result = new(mock.cwd.path()).call(args)
    @json.inspect(mock.json(result), content=[
      "Ok",
      {
        "diagnostics": [
          "Diagnostics",
          [
            {
              "error_code": 2,
              "level": "Warning",
              "loc": {
                "end": { "col": 6, "line": 2 },
                "path": "(mock:cwd)/example.mbt",
                "start": { "col": 5, "line": 2 },
              },
              "message": "Warning (unused_value): Unused variable 'x'",
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
        ],
        "diagnostic_limit": 10,
        "rendered_diagnostics": "MoonBit project check found the following diagnostics:\n\nerror[4014]: (mock:cwd)/example.mbt:2:15-23: Expr Type Mismatch\n        has type : String\n        wanted   : Int\n 2 │ let x : Int = \"string\"\n   │               ^^^^^^^^\n\nwarning[0002]: (mock:cwd)/example.mbt:2:5-6: Warning (unused_value): Unused variable 'x'\n 2 │ let x : Int = \"string\"\n   │     ^",
      },
    ])
    inspect(
      mock.show(result),
      content=(
        #|MoonBit project check found the following diagnostics:
        #|
        #|error[4014]: (mock:cwd)/example.mbt:2:15-23: Expr Type Mismatch
        #|        has type : String
        #|        wanted   : Int
        #| 2 │ let x : Int = "string"
        #|   │               ^^^^^^^^
        #|
        #|warning[0002]: (mock:cwd)/example.mbt:2:5-6: Warning (unused_value): Unused variable 'x'
        #| 2 │ let x : Int = "string"
        #|   │     ^
      ),
    )
  })
}

///|
async test "check_moonbit_project/code-patch-insert" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "moon.mod.json": { "name": "example", "version": "0.1.0" }
      .to_json()
      .stringify(),
      "moon.pkg.json": Json::object({}).stringify(),
      "example.mbt": (
        #|///|
        #|let x : Int = "string"
        #|
      ),
    })
    let args = input_json(
      diagnostic_limit=10,
      project_path=mock.cwd.path(),
      patch_code="let y : String = 42",
      patch_file_name="example.mbt",
    )
    let result = new(mock.cwd.path()).call(args)

    // Note we don't really change the file
    inspect(
      @fsx.read_file(@pathx.join(mock.cwd.path(), "example.mbt")),
      content=(
        #|///|
        #|let x : Int = "string"
        #|
      ),
    )
    @json.inspect(mock.json(result), content=[
      "Ok",
      {
        "diagnostics": [
          "Diagnostics",
          [
            {
              "error_code": 2,
              "level": "Warning",
              "loc": {
                "end": { "col": 6, "line": 1 },
                "path": "(mock:cwd)/example.mbt",
                "start": { "col": 5, "line": 1 },
              },
              "message": "Warning (unused_value): Unused variable 'y'",
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
        ],
        "diagnostic_limit": 10,
        "rendered_diagnostics": "MoonBit project check found the following diagnostics:\n\nerror[4014]: (mock:cwd)/example.mbt:1:18-20: Expr Type Mismatch\n        has type : Int\n        wanted   : String\n 1 │ let y : String = 42\n   │                  ^^\n\nwarning[0002]: (mock:cwd)/example.mbt:1:5-6: Warning (unused_value): Unused variable 'y'\n 1 │ let y : String = 42\n   │     ^",
      },
    ])
    inspect(
      mock.show(result),
      content=(
        #|MoonBit project check found the following diagnostics:
        #|
        #|error[4014]: (mock:cwd)/example.mbt:1:18-20: Expr Type Mismatch
        #|        has type : Int
        #|        wanted   : String
        #| 1 │ let y : String = 42
        #|   │                  ^^
        #|
        #|warning[0002]: (mock:cwd)/example.mbt:1:5-6: Warning (unused_value): Unused variable 'y'
        #| 1 │ let y : String = 42
        #|   │     ^
      ),
    )
  })
}

///|
async test "check_moonbit_project/test-patch-insert" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "moon.mod.json": { "name": "username/example", "version": "0.1.0" }
      .to_json()
      .stringify(),
      "moon.pkg.json": Json::object({}).stringify(),
      "example.mbt": (
        #|///|
        #|pub let x : Int = 42
        #|
      ),
    })
    let args = @check_moonbit_project.input_json(
      diagnostic_limit=10,
      project_path=mock.cwd.path(),
      patch_code=(
        #|test "patched-test" {
        #|  @json.inspect(@example.x, "string")
        #|}
      ),
      patch_file_name="example_test.mbt",
    )
    let tool = @check_moonbit_project.new(mock.cwd.path())
    let result = tool.call(args)
    @json.inspect(mock.json(result), content=[
      "Ok",
      {
        "diagnostics": [
          "Diagnostics",
          [
            {
              "error_code": 4080,
              "level": "Error",
              "loc": {
                "end": { "col": 38, "line": 2 },
                "path": "(mock:cwd)/example_test.mbt",
                "start": { "col": 3, "line": 2 },
              },
              "message": "This function has type: \n\t#callsite(autofill(args_loc, loc))\n\t(&ToJson, content? : Json, loc~ : SourceLoc, args_loc~ : ArgsLoc) -> Unit raise InspectError\nwhich requires 1 positional arguments, but is given 2 positional arguments.",
            },
          ],
        ],
        "diagnostic_limit": 10,
        "rendered_diagnostics": "MoonBit project check found the following diagnostics:\n\nerror[4080]: (mock:cwd)/example_test.mbt:2:3-38: This function has type: \n\t#callsite(autofill(args_loc, loc))\n\t(&ToJson, content? : Json, loc~ : SourceLoc, args_loc~ : ArgsLoc) -> Unit raise InspectError\nwhich requires 1 positional arguments, but is given 2 positional arguments.\n 2 │   @json.inspect(@example.x, \"string\")\n   │   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
      },
    ])
    inspect(
      mock.show(result),
      content=(
        #|MoonBit project check found the following diagnostics:
        #|
        #|error[4080]: (mock:cwd)/example_test.mbt:2:3-38: This function has type: 
        $|\t#callsite(autofill(args_loc, loc))
        $|\t(&ToJson, content? : Json, loc~ : SourceLoc, args_loc~ : ArgsLoc) -> Unit raise InspectError
        #|which requires 1 positional arguments, but is given 2 positional arguments.
        #| 2 │   @json.inspect(@example.x, "string")
        #|   │   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      ),
    )
  })
}
