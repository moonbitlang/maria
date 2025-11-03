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
  let path = "main.mbt"
  let content =
    #|enum Color {
    #|  Red,
    #|  Green,
    #|  Blue,
    #|}
    #|
    #|fn Color::to_string(self : Color) -> String {
    #|  switch self {
    #|    Red => "red",
    #|    Green => "green",
    #|    Blue => "blue",
    #|  }
    #|}
    #|
    #|fn main() {
    #|
    #|  let color : Color = Blue
    #|  println(color.to_string())
    #|}
  let diagnostics = @moon.check_syntax_of_string(path~, content)
  inspect(
    render_diagnostics(path~, content, diagnostics),
    content=(
      #|error[3800]: main.mbt:2:6-7: Expecting a newline or `;` here, but encountered `,`.
      #|   │ enum Color {
      #| 2 │   Red,
      #|   │      ^
      #|   │   Green,
      #|
      #|error[3800]: main.mbt:3:8-9: Expecting a newline or `;` here, but encountered `,`.
      #|   │   Red,
      #| 3 │   Green,
      #|   │        ^
      #|   │   Blue,
      #|
      #|error[3800]: main.mbt:4:7-8: Expecting a newline or `;` here, but encountered `,`.
      #|   │   Green,
      #| 4 │   Blue,
      #|   │       ^
      #|   │ }
      #|
      #|error[3002]: main.mbt:8:10-14: Parse error, unexpected token id (lowercase start), you may expect `;` or `}`.
      #|   │ fn Color::to_string(self : Color) -> String {
      #| 8 │   switch self {
      #|   │          ^^^^
      #|   │     Red => "red",
      #|
      #|error[3002]: main.mbt:14:2: Parse error, unexpected token `}`, you may expect `pub`, `priv`, `type`, `suberror`, `typealias`, `async`, `fn`, `fnalias`, `struct`, `enum`, `let`, `const`, `extern`, `test`, `impl`, `trait`, `traitalias`, `enumview`, `#attribute` or `using`.
      #|    │ }
      #| 14 │
      #|    │  ^
      #|    │ fn main() {
      #|
      #|error[3003]: main.mbt:15:8-10: Unused parameter list for the main function. The syntax is `fn main { ... }`
      #|    │
      #| 15 │ fn main() {
      #|    │        ^^
      #|    │
    ),
  )
}
