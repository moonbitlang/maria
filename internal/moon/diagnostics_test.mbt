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
      ("example.mbt", "let x : Int = \"string\""),
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
      mock.show(@moon.render_diagnostics(diagnostics, limit=10)),
      content=(
        #|error[4014]: (mock:cwd)/example.mbt:1:15-23: Expr Type Mismatch
        #|        has type : String
        #|        wanted   : Int
        #| 1 │ let x : Int = "string"
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
        #|warning[0002]: (mock:cwd)/example.mbt:1:5-6: Warning: Unused variable 'x'
        #| 1 │ let x : Int = "string"
        #|   │     ^
        #|
        #|warning[0002]: (mock:cwd)/example2.mbt:2:7-8: Warning: Unused variable 'y'
        #| 2 │   let y = "hello"
        #|   │       ^
      ),
    )
    inspect(
      mock.show(@moon.render_diagnostics(diagnostics, limit=1)),
      content=(
        #|error[4014]: (mock:cwd)/example.mbt:1:15-23: Expr Type Mismatch
        #|        has type : String
        #|        wanted   : Int
        #| 1 │ let x : Int = "string"
        #|   │               ^^^^^^^^
        #|
        #|There are 2 more error(s) and 2 more warning(s) not shown due to diagnostic limit.
      ),
    )
  })
}
