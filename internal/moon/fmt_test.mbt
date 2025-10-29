///|
async test "format_string" {
  let formatted = @moon.format_string(
    (
      #|fn main { println("Hello, world!") }
    ),
  )
  inspect(
    formatted,
    content=(
      #|///|
      #|fn main {
      #|  println("Hello, world!")
      #|}
      #|
    ),
  )
}
