///|
async test "check" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "moon.mod.json": (
        #|{ "name": "example", "version": "0.1.0" }
      ),
      "moon.pkg.json": (
        #|{ }
      ),
      "example.mbt": "let x : Int = \"string\"",
    })
    let diagnostics = check(cwd=mock.cwd.path())
    @json.inspect(mock.json(diagnostics), content=[
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
          "message": "Warning (unused_value): Unused variable 'x'",
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
      ],
    ])
  })
}

///|
async test "check_syntax_of_file" (t : @test.Test) {
  @mock.run(t, mock => {
    let file = mock.add_file("example.mbt")
    file.write_string("let x :: Int = \"string\"")
    let diagnostics = check_syntax_of_file(file.path())
    @json.inspect(mock.json(diagnostics), content=[
      "Diagnostics",
      [
        {
          "error_code": 3002,
          "level": "Error",
          "loc": {
            "end": { "col": 9, "line": 1 },
            "path": "example.mbt",
            "start": { "col": 7, "line": 1 },
          },
          "message": "Parse error, unexpected token `::`, you may expect `=`.",
        },
      ],
    ])
  })
}
