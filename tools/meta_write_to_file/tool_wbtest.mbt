///|
async test "render_diagnostics" {
  let path = "json_parser/json_parser.mbt"
  let content =
    #|///|
    #|let x : Int = "String",
  let diagnostics = @moon.check_syntax_of_string(path~, content)
  inspect(
    render_diagnostics(path~, content, diagnostics),
    content=(
      #|error[3002]: json_parser.mbt:2:24: Parse error, unexpected token `,`, you may expect `pub`, `priv`, `type`, `suberror`, `typealias`, `async`, `fn`, `fnalias`, `struct`, `enum`, `let`, `const`, `extern`, `test`, `impl`, `trait`, `traitalias`, `enumview`, `#attribute` or `using`.
      #|   │ ///|
      #| 2 │ let x : Int = "String",
      #|   │                        ^
    ),
  )
  let content =
    #|let x : Int = ("String"aaa
  let diagnostics = @moon.check_syntax_of_string(path~, content)
  inspect(
    render_diagnostics(path~, content, diagnostics),
    content=(
      #|error[3002]: json_parser.mbt:1:24-27: Parse error, unexpected token id (lowercase start), you may expect `,` or `)`.
      #| 1 │ let x : Int = ("String"aaa
      #|   │                        ^^^
    ),
  )
}
