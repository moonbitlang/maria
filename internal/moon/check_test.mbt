///|
async test "check_syntax_of_string" {
  json_inspect(
    @moon.check_syntax_of_string(
      (
        #|let x : Int = "string",
      ),
    ),
    content=[
      "Diagnostics",
      [
        {
          "error_code": 3002,
          "level": "Error",
          "loc": {
            "end": { "col": 24, "line": 1 },
            "path": "source.mbt",
            "start": { "col": 24, "line": 1 },
          },
          "message": "Parse error, unexpected token `,`, you may expect `pub`, `priv`, `type`, `suberror`, `typealias`, `async`, `fn`, `fnalias`, `struct`, `enum`, `let`, `const`, `extern`, `test`, `impl`, `trait`, `traitalias`, `enumview`, `#attribute` or `using`.",
        },
      ],
    ],
  )
  json_inspect(
    @moon.check_syntax_of_string(
      path="main.mbt",
      (
        #|let x : Int = "string",
      ),
    ),
    content=[
      "Diagnostics",
      [
        {
          "error_code": 3002,
          "level": "Error",
          "loc": {
            "end": { "col": 24, "line": 1 },
            "path": "main.mbt",
            "start": { "col": 24, "line": 1 },
          },
          "message": "Parse error, unexpected token `,`, you may expect `pub`, `priv`, `type`, `suberror`, `typealias`, `async`, `fn`, `fnalias`, `struct`, `enum`, `let`, `const`, `extern`, `test`, `impl`, `trait`, `traitalias`, `enumview`, `#attribute` or `using`.",
        },
      ],
    ],
  )
}

///|
async test "check_syntax_of_string-nested-path" {
  let diagnostics = check_syntax_of_string(
    path=@pathx.join("src", "main.mbt"),
    (
      #|let x : Int = "string",
    ),
  )
  json_inspect(diagnostics, content=[
    "Diagnostics",
    [
      {
        "error_code": 3002,
        "level": "Error",
        "loc": {
          "end": { "col": 24, "line": 1 },
          "path": "main.mbt",
          "start": { "col": 24, "line": 1 },
        },
        "message": "Parse error, unexpected token `,`, you may expect `pub`, `priv`, `type`, `suberror`, `typealias`, `async`, `fn`, `fnalias`, `struct`, `enum`, `let`, `const`, `extern`, `test`, `impl`, `trait`, `traitalias`, `enumview`, `#attribute` or `using`.",
      },
    ],
  ])
}

///|
async test "check_syntax_of_file" (t : @test.Test) {
  @mock.run(t, mock => {
    let file = mock.add_file("example.mbt")
    file.write_string("let x :: Int = \"string\"")
    let diagnostics = check_syntax_of_file(file.path())
    json_inspect(mock.json(diagnostics), content=[
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
