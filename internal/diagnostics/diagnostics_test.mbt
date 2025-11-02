///|
async test "render_diagnostics" (t : @test.T) {
  @mock.run(t, mock => {
    mock.add_files([
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
      (
        "example.mbt",
        (
          #|///|
          #|let x : Int = "string"
        ),
      ),
      (
        "example2.mbt",
        (
          #|fn main() {
          #|  let y = "hello"
          #|}
        ),
      ),
    ])
    let moon = @moon.Module::load(mock.cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics().collect()
    inspect(
      mock.show(@diagnostics.render_diagnostics(diagnostics, limit=10)),
      content=(
        #|error[4014]: (mock:cwd)/example.mbt:2:15-23: Expr Type Mismatch
        #|        has type : String
        #|        wanted   : Int
        #| 2 │ let x : Int = "string"
        #|   │               ^^^^^^^^
        #|
        #|error[3003]: (mock:cwd)/example2.mbt:1:8-10: Unused parameter list for the main function. The syntax is `fn main { ... }`
        #| 1 │ fn main() {
        #|   │        ^^
        #|
        #|error[4069]: (mock:cwd)/example2.mbt:1:1-3:2: Unexpected main function in the non-main package.
        #| 1 │ fn main() {
        #|   │ ^^^^^^^^^^^
        #|   ┆
        #| 3 │ }
        #|   │ ^
        #|
        #|warning[0002]: (mock:cwd)/example.mbt:2:5-6: Warning: Unused variable 'x'
        #| 2 │ let x : Int = "string"
        #|   │     ^
        #|
        #|warning[0002]: (mock:cwd)/example2.mbt:2:7-8: Warning: Unused variable 'y'
        #| 2 │   let y = "hello"
        #|   │       ^
      ),
    )
    inspect(
      mock.show(@diagnostics.render_diagnostics(diagnostics, limit=1)),
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
async test "render-diagnostics-context" (t : @test.T) {
  @mock.run(t, mock => {
    mock.add_files([
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
      (
        "example.mbt",
        (
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
      ),
    ])
    let moon = @moon.Module::load(mock.cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics().collect()
    inspect(
      mock.show(
        @diagnostics.render_diagnostics(diagnostics, context=1, limit=10),
      ),
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
        #|warning[0001]: (mock:cwd)/example.mbt:2:4-19: Warning: Unused function 'skip_whitespace'
        #|   │ ///|
        #| 2 │ fn skip_whitespace(lexer : Lexer) -> Unit {
        #|   │    ^^^^^^^^^^^^^^^
        #|   │   loop {
        #|
        #|warning[0018]: (mock:cwd)/example.mbt:3:3-9:2: Warning: There is no [continue] in this loop expression, so [loop] is useless here.
        #|   │ fn skip_whitespace(lexer : Lexer) -> Unit {
        #| 3 │   loop {
        #|   │   ^^^^^^
        #|   ┆
        #| 9 │ }
        #|   │ ^
      ),
    )
    inspect(
      mock.show(@diagnostics.render_diagnostics(diagnostics, limit=1)),
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
