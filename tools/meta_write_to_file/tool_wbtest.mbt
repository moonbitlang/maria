///|
async test "check_syntax_errors_of_string" {
  let path = "a.mbt"
  let content =
    #|struct A {
    #|  val : Int
    #|}
    #|fn main {
    #|  let a = A { val: "not an int" }
    #|}
  inspect(
    check_syntax_errors_of_string(path~, content),
    content=(
      #|error[3002]: a.mbt: Parse error, unexpected token `{`, you may expect `;` or `}`.
      #| 5 │   let a = A { val: "not an int" }
      #|   │             ^
      #|
      #|error[3002]: a.mbt: Parse error, unexpected token `}`, you may expect `pub`, `priv`, `type`, `suberror`, `typealias`, `async`, `fn`, `fnalias`, `struct`, `enum`, `let`, `const`, `extern`, `test`, `impl`, `trait`, `traitalias`, `enumview`, `#attribute` or `using`.
      #| 6 │ }
      #|   │  
      #|
      #|There are 2 more error(s) not shown due to diagnostic limit.
    ),
  )
}

///|
async test "check_syntax_errors_of_file" (t : @test.T) {
  @mock.run(t, mock => {
    let _ = mock.add_file(
      "b.mbt",
      content=(
        #|struct B {
        #|  name : String
        #|}
        #|fn main {
        #|  let b = B { name: 123 }
        #|}
      ),
    )
    inspect(
      check_syntax_errors_of_file(path="b.mbt", cwd=mock.cwd.path()),
      content=(
        #|error[3002]: b.mbt: Parse error, unexpected token `{`, you may expect `;` or `}`.
        #| 5 │   let b = B { name: 123 }
        #|   │             ^
        #|
        #|error[3002]: b.mbt: Parse error, unexpected token `}`, you may expect `pub`, `priv`, `type`, `suberror`, `typealias`, `async`, `fn`, `fnalias`, `struct`, `enum`, `let`, `const`, `extern`, `test`, `impl`, `trait`, `traitalias`, `enumview`, `#attribute` or `using`.
        #| 6 │ }
        #|   │  
        #|
        #|There are 2 more error(s) not shown due to diagnostic limit.
      ),
    )
  })
}
