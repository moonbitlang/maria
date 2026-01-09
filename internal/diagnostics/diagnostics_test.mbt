///|
async test "render_diagnostics" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_files({
      "moon.mod.json": (
        #|{ "name": "example", "version": "0.1.0" }
      ),
      "moon.pkg.json": (
        #|{ }
      ),
      "example.mbt": (
        #|///|
        #|let x : Int = "string"
      ),
      "example2.mbt": (
        #|fn main() {
        #|  let y = "hello"
        #|}
      ),
    })
    let moon = @moon.Module::load(mock.cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics()
    inspect(
      mock.show(diagnostics.render(limit=10)),
      content=(
        #|error[4014]: (mock:cwd)/example.mbt:2:15-23: Expr Type Mismatch
        #|        has type : String
        #|        wanted   : Int
        #| 2 │ let x : Int = "string"
        #|   │               ^^^^^^^^
        #|
        #|error[4069]: (mock:cwd)/example2.mbt:1:1-3:2: Unexpected main function in the non-main package.
        #| 1 │ fn main() {
        #|   │ ^^^^^^^^^^^
        #|   ┆
        #| 3 │ }
        #|   │ ^
        #|
        #|error[3003]: (mock:cwd)/example2.mbt:1:8-10: Unused parameter list for the main function. The syntax is `fn main { ... }`
        #| 1 │ fn main() {
        #|   │        ^^
        #|
        #|warning[0002]: (mock:cwd)/example.mbt:2:5-6: Warning (unused_value): Unused variable 'x'
        #| 2 │ let x : Int = "string"
        #|   │     ^
        #|
        #|warning[0002]: (mock:cwd)/example2.mbt:2:7-8: Warning (unused_value): Unused variable 'y'
        #| 2 │   let y = "hello"
        #|   │       ^
      ),
    )
    inspect(
      mock.show(diagnostics.render(limit=1)),
      content=(
        #|error[4014]: (mock:cwd)/example.mbt:2:15-23: Expr Type Mismatch
        #|        has type : String
        #|        wanted   : Int
        #| 2 │ let x : Int = "string"
        #|   │               ^^^^^^^^
        #|
        #|There are 2 more error(s) and 2 more warning(s) not shown due to diagnostic limit.
      ),
    )
  })
}

///|
async test "render-diagnostics-context" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_files({
      "moon.mod.json": (
        #|{ "name": "example", "version": "0.1.0" }
      ),
      "moon.pkg.json": (
        #|{ }
      ),
      "example.mbt": (
        #|///|
        #|fn skip_whitespace(lexer : Lexer) -> Unit {
        #|  loop {
        #|    match lexer.ch {
        #|      Some(' ' | '\t' | '\r' | '\n') => { read_char(lexer) }
        #|      _ => { break }
        #|    }
        #|  }
        #|}
      ),
    })
    let moon = @moon.Module::load(mock.cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics()
    inspect(
      mock.show(diagnostics.render(context=1, limit=10)),
      content=(
        #|error[4032]: (mock:cwd)/example.mbt:2:28-33: The type Lexer is undefined.
        #|   │ ///|
        #| 2 │ fn skip_whitespace(lexer : Lexer) -> Unit {
        #|   │                            ^^^^^
        #|   │   loop {
        #|
        #|error[4021]: (mock:cwd)/example.mbt:5:43-52: The value identifier read_char is unbound.
        #|   │     match lexer.ch {
        #| 5 │       Some(' ' | '\t' | '\r' | '\n') => { read_char(lexer) }
        #|   │                                           ^^^^^^^^^
        #|   │       _ => { break }
        #|
        #|error[4102]: (mock:cwd)/example.mbt:6:14-19: 'break' outside of a loop
        #|   │       Some(' ' | '\t' | '\r' | '\n') => { read_char(lexer) }
        #| 6 │       _ => { break }
        #|   │              ^^^^^
        #|   │     }
        #|
        #|error[3002]: (mock:cwd)/example.mbt:9:1-2: Parse error, unexpected token `}`, you may expect `{`.
        #|   │   }
        #| 9 │ }
        #|   │ ^
        #|
        #|warning[0001]: (mock:cwd)/example.mbt:2:4-19: Warning (unused_value): Unused function 'skip_whitespace'
        #|   │ ///|
        #| 2 │ fn skip_whitespace(lexer : Lexer) -> Unit {
        #|   │    ^^^^^^^^^^^^^^^
        #|   │   loop {
        #|
        #|warning[0018]: (mock:cwd)/example.mbt:3:3-9:2: Warning (useless_loop): There is no [continue] in this loop expression, so [loop] is useless here.
        #|   │ fn skip_whitespace(lexer : Lexer) -> Unit {
        #| 3 │   loop {
        #|   │   ^^^^^^
        #|   ┆
        #| 9 │ }
        #|   │ ^
      ),
    )
    inspect(
      mock.show(diagnostics.render(limit=1)),
      content=(
        #|error[4032]: (mock:cwd)/example.mbt:2:28-33: The type Lexer is undefined.
        #| 2 │ fn skip_whitespace(lexer : Lexer) -> Unit {
        #|   │                            ^^^^^
        #|
        #|There are 3 more error(s) and 2 more warning(s) not shown due to diagnostic limit.
      ),
    )
  })
}

///|
async test "render-diagnostics-overlay" (t : @test.Test) {
  @mock.run(t, mock => {
    let diagnostics = @diagnostics.Diagnostics::new()
    diagnostics.push({
      error_code: 1234,
      level: @diagnostics.Error,
      loc: {
        start: { line: 2, col: 5 },
        end: { line: 2, col: 6 },
        path: "virtual.mbt",
      },
      message: "Example error",
    })
    let overlay = {}
    overlay["virtual.mbt"] = (
      #|///|
      #|/// Example MoonBit code
      #|let x : Int = 1
      #|let y : Int = 2
    )
    inspect(
      mock.show(diagnostics.render(limit=1, overlay~, context=2)),
      content=(
        #|error[1234]: virtual.mbt:2:5-6: Example error
        #|   │ ///|
        #| 2 │ /// Example MoonBit code
        #|   │     ^
        #|   │ let x : Int = 1
      ),
    )
  })
}

///|
async test "render-diagnostics-context-lines" (t : @test.Test) {
  @mock.run(t, mock => {
    let diagnostics = @diagnostics.Diagnostics::new()
    diagnostics.push(@diagnostics.Diagnostic::{
      error_code: 1234,
      level: @diagnostics.Error,
      loc: @diagnostics.Loc::{
        start: @diagnostics.Pos::{ line: 2, col: 5 },
        end: @diagnostics.Pos::{ line: 2, col: 6 },
        path: "virtual.mbt",
      },
      message: "Example error",
    })
    let overlay = {}
    overlay["virtual.mbt"] = (
      #|let x : Int = 1
      #|let y : Int = 2
      #|let z : Int = 3
    )
    inspect(
      mock.show(diagnostics.render(context=1, limit=1, overlay~)),
      content=(
        #|error[1234]: virtual.mbt:2:5-6: Example error
        #|   │ let x : Int = 1
        #| 2 │ let y : Int = 2
        #|   │     ^
      ),
    )
  })
}

///|
test "from_jsonl - single diagnostic" {
  let jsonl =
    #|{"error_code":4014,"level":"error","loc":{"end":{"col":23,"line":1},"path":"example.mbt","start":{"col":15,"line":1}},"message":"Expr Type Mismatch"}
  let diagnostics = @diagnostics.from_jsonl(jsonl)
  @json.inspect(diagnostics, content=[
    "Diagnostics",
    [
      {
        "error_code": 4014,
        "level": "Error",
        "loc": {
          "end": { "col": 23, "line": 1 },
          "path": "example.mbt",
          "start": { "col": 15, "line": 1 },
        },
        "message": "Expr Type Mismatch",
      },
    ],
  ])
}

///|
test "from_jsonl - multiple diagnostics" {
  let jsonl =
    #|{"error_code":4014,"level":"error","loc":{"end":{"col":23,"line":1},"path":"example.mbt","start":{"col":15,"line":1}},"message":"Expr Type Mismatch"}
    #|{"error_code":2,"level":"warning","loc":{"end":{"col":6,"line":1},"path":"test.mbt","start":{"col":5,"line":1}},"message":"Warning: Unused variable"}
    #|{"error_code":3003,"level":"error","loc":{"end":{"col":10,"line":2},"path":"main.mbt","start":{"col":8,"line":2}},"message":"Parse error"}
  let diagnostics = @diagnostics.from_jsonl(jsonl)
  @json.inspect(diagnostics, content=[
    "Diagnostics",
    [
      {
        "error_code": 4014,
        "level": "Error",
        "loc": {
          "end": { "col": 23, "line": 1 },
          "path": "example.mbt",
          "start": { "col": 15, "line": 1 },
        },
        "message": "Expr Type Mismatch",
      },
      {
        "error_code": 2,
        "level": "Warning",
        "loc": {
          "end": { "col": 6, "line": 1 },
          "path": "test.mbt",
          "start": { "col": 5, "line": 1 },
        },
        "message": "Warning: Unused variable",
      },
      {
        "error_code": 3003,
        "level": "Error",
        "loc": {
          "end": { "col": 10, "line": 2 },
          "path": "main.mbt",
          "start": { "col": 8, "line": 2 },
        },
        "message": "Parse error",
      },
    ],
  ])
}

///|
test "from_jsonl - empty string" {
  let jsonl = ""
  let diagnostics = @diagnostics.from_jsonl(jsonl)
  @json.inspect(diagnostics, content=["Diagnostics", []])
}

///|
test "from_jsonl - empty lines" {
  let jsonl =
    #|{"error_code":4014,"level":"error","loc":{"end":{"col":23,"line":1},"path":"example.mbt","start":{"col":15,"line":1}},"message":"Expr Type Mismatch"}
    #|
    #|{"error_code":2,"level":"warning","loc":{"end":{"col":6,"line":1},"path":"test.mbt","start":{"col":5,"line":1}},"message":"Warning: Unused variable"}
  let diagnostics = @diagnostics.from_jsonl(jsonl)
  @json.inspect(diagnostics, content=[
    "Diagnostics",
    [
      {
        "error_code": 4014,
        "level": "Error",
        "loc": {
          "end": { "col": 23, "line": 1 },
          "path": "example.mbt",
          "start": { "col": 15, "line": 1 },
        },
        "message": "Expr Type Mismatch",
      },
      {
        "error_code": 2,
        "level": "Warning",
        "loc": {
          "end": { "col": 6, "line": 1 },
          "path": "test.mbt",
          "start": { "col": 5, "line": 1 },
        },
        "message": "Warning: Unused variable",
      },
    ],
  ])
}

///|
test "from_jsonl - whitespace handling" {
  let jsonl =
    #|  {"error_code":4014,"level":"error","loc":{"end":{"col":23,"line":1},"path":"example.mbt","start":{"col":15,"line":1}},"message":"Expr Type Mismatch"}  
    #|
    #|  {"error_code":2,"level":"warning","loc":{"end":{"col":6,"line":1},"path":"test.mbt","start":{"col":5,"line":1}},"message":"Warning: Unused variable"}  
  let diagnostics = @diagnostics.from_jsonl(jsonl)
  @json.inspect(diagnostics, content=[
    "Diagnostics",
    [
      {
        "error_code": 4014,
        "level": "Error",
        "loc": {
          "end": { "col": 23, "line": 1 },
          "path": "example.mbt",
          "start": { "col": 15, "line": 1 },
        },
        "message": "Expr Type Mismatch",
      },
      {
        "error_code": 2,
        "level": "Warning",
        "loc": {
          "end": { "col": 6, "line": 1 },
          "path": "test.mbt",
          "start": { "col": 5, "line": 1 },
        },
        "message": "Warning: Unused variable",
      },
    ],
  ])
}

///|
test "from_jsonl - round trip" {
  let original : Array[@diagnostics.Diagnostic] = [
    @diagnostics.Diagnostic::{
      error_code: 4014,
      level: @diagnostics.Error,
      loc: @diagnostics.Loc::{
        end: @diagnostics.Pos::{ col: 23, line: 1 },
        path: "example.mbt",
        start: @diagnostics.Pos::{ col: 15, line: 1 },
      },
      message: "Expr Type Mismatch",
    },
    @diagnostics.Diagnostic::{
      error_code: 2,
      level: @diagnostics.Warning,
      loc: @diagnostics.Loc::{
        end: @diagnostics.Pos::{ col: 6, line: 1 },
        path: "test.mbt",
        start: @diagnostics.Pos::{ col: 5, line: 1 },
      },
      message: "Warning: Unused variable",
    },
  ]
  let jsonl_str = original
    .iter()
    .map(fn(d) { d.to_json().stringify() })
    .to_array()
    .join("\n")
  let parsed = @diagnostics.from_jsonl(jsonl_str)
  @json.inspect(parsed, content=[
    "Diagnostics",
    [
      {
        "error_code": 4014,
        "level": "Error",
        "loc": {
          "end": { "col": 23, "line": 1 },
          "path": "example.mbt",
          "start": { "col": 15, "line": 1 },
        },
        "message": "Expr Type Mismatch",
      },
      {
        "error_code": 2,
        "level": "Warning",
        "loc": {
          "end": { "col": 6, "line": 1 },
          "path": "test.mbt",
          "start": { "col": 5, "line": 1 },
        },
        "message": "Warning: Unused variable",
      },
    ],
  ])
}

///|
async test "render_empty_line" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_files({
      "moon.mod.json": (
        #|{ "name": "example", "version": "0.1.0" }
      ),
      "moon.pkg.json": (
        #|{ }
      ),
      "example.mbt": (
        #|struct Point {
        #|  x : Int
        #|  y : Int
        #|}
        #|
        #|fn Point::new(x~ : Int, y~ : Int) -> Point {
        #|  Point { x, y }
        #|}
        #|
        #|#load
        #|
        #|/// Well
        #|fn main {
        #|  println("Hello, World!")
        #|}
      ),
    })
    let moon = @moon.Module::load(mock.cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics()
    inspect(
      mock.show(diagnostics.render(context=1, limit=10)),
      content=(
        #|error[3002]: (mock:cwd)/example.mbt:7:9-10: Unexpected `{` after `Point`, missing `::` here.
        #|Hint: To construct a record, use the syntax `Point::{ field1: value1, field2: value2 }`. If the type can be inferred, you may omit the `Point::` part.
        #|   │ fn Point::new(x~ : Int, y~ : Int) -> Point {
        #| 7 │   Point { x, y }
        #|   │         ^
        #|   │ }
        #|
        #|error[4069]: (mock:cwd)/example.mbt:10:1-15:2: Unexpected main function in the non-main package.
        #|    │
        #| 10 │ #load
        #|    │ ^^^^^
        #|    ┆
        #| 15 │ }
        #|    │ ^
        #|
        #|warning[0004]: (mock:cwd)/example.mbt:1:8-13: Warning (missing_priv): The type 'Point' does not occur in public signature of current package, consider marking it as `priv`.
        #| 1 │ struct Point {
        #|   │        ^^^^^
        #|   │   x : Int
        #|
        #|warning[0007]: (mock:cwd)/example.mbt:2:3-4: Warning (unused_field): Field 'x' is never read
        #|   │ struct Point {
        #| 2 │   x : Int
        #|   │   ^
        #|   │   y : Int
        #|
        #|warning[0007]: (mock:cwd)/example.mbt:3:3-4: Warning (unused_field): Field 'y' is never read
        #|   │   x : Int
        #| 3 │   y : Int
        #|   │   ^
        #|   │ }
        #|
        #|warning[0001]: (mock:cwd)/example.mbt:6:11-14: Warning (unused_value): Unused function 'new'
        #|   │
        #| 6 │ fn Point::new(x~ : Int, y~ : Int) -> Point {
        #|   │           ^^^
        #|   │   Point { x, y }
        #|
        #|warning[0042]: (mock:cwd)/example.mbt:10:1-6: Warning (invalid_attribute): unknown attribute load
        #|    │
        #| 10 │ #load
        #|    │ ^^^^^
        #|    │
      ),
    )
    inspect(
      mock.show(diagnostics.render(limit=1)),
      content=(
        #|error[3002]: (mock:cwd)/example.mbt:7:9-10: Unexpected `{` after `Point`, missing `::` here.
        #|Hint: To construct a record, use the syntax `Point::{ field1: value1, field2: value2 }`. If the type can be inferred, you may omit the `Point::` part.
        #| 7 │   Point { x, y }
        #|   │         ^
        #|
        #|There are 1 more error(s) and 5 more warning(s) not shown due to diagnostic limit.
      ),
    )
  })
}

///|
async test "render_diagnostics_with_context_2" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_files({
      "moon.mod.json": Json::object({ "name": "example", "version": "0.1.0" }).stringify(
        indent=2,
      ),
      "moon.pkg.json": Json::object({ "is-main": true }).stringify(indent=2),
      "main.mbt": (
        #|enum Color {
        #|  Red
        #|  Green
        #|  Blue
        #|}
        #|
        #|fn Color::to_string(self : Color) -> String {
        #|  match self {
        #|    Red => "red",
        #|    Green => "green",
        #|    Blue => "blue",
        #|  }
        #|}
        #|
        #|fn main {
        #|  let color : Color = Blue
        #|  println(color.to_string())
        #|}
      ),
    })
    let moon = @moon.Module::load(mock.cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics()
    inspect(
      mock.show(diagnostics.render(context=2, limit=10)),
      content=(
        #|error[3800]: (mock:cwd)/main.mbt:9:17-18: Expecting a newline or `;` here, but encountered `,`.
        #|    │ fn Color::to_string(self : Color) -> String {
        #|    │   match self {
        #|  9 │     Red => "red",
        #|    │                 ^
        #|    │     Green => "green",
        #|    │     Blue => "blue",
        #|
        #|error[3800]: (mock:cwd)/main.mbt:10:21-22: Expecting a newline or `;` here, but encountered `,`.
        #|    │   match self {
        #|    │     Red => "red",
        #| 10 │     Green => "green",
        #|    │                     ^
        #|    │     Blue => "blue",
        #|    │   }
        #|
        #|error[3800]: (mock:cwd)/main.mbt:11:19-20: Expecting a newline or `;` here, but encountered `,`.
        #|    │     Red => "red",
        #|    │     Green => "green",
        #| 11 │     Blue => "blue",
        #|    │                   ^
        #|    │   }
        #|    │ }
        #|
        #|warning[0006]: (mock:cwd)/main.mbt:2:3-6: Warning (unused_constructor): Variant 'Red' is never constructed
        #|   │ enum Color {
        #| 2 │   Red
        #|   │   ^^^
        #|   │   Green
        #|   │   Blue
        #|
        #|warning[0006]: (mock:cwd)/main.mbt:3:3-8: Warning (unused_constructor): Variant 'Green' is never constructed
        #|   │ enum Color {
        #|   │   Red
        #| 3 │   Green
        #|   │   ^^^^^
        #|   │   Blue
        #|   │ }
      ),
    )
  })
}
