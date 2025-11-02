///|
async test "format_string" {
  let input = [
    (
      #|fn main {println("Hello, world!")}
    ),
    (
      #|struct Point {x: Int,y: Int}
    ),
    /// TODO: this is not formatted properly
    (
      #|enum Shape { Circle(radius: Int), Square(side: Int) }
    ),
  ]

  // let format_all = input.map(x => try? @moon.format_string(x))
  // no async map ?
  let format_all = []
  for item in input {
    let formatted = try? @moon.format_string(item)
    format_all.push(formatted)
  }
  @json.inspect(format_all, content=[
    { "Ok": "///|\nfn main {\n  println(\"Hello, world!\")\n}\n" },
    { "Ok": "///|\nstruct Point {\n  x : Int\n  y : Int\n}\n" },
    { "Ok": "enum Shape { Circle(radius: Int), Square(side: Int) }\n" },
  ])
  // let formatted = @moon.format_string(
  //   (
  //     #|fn main { println("Hello, world!") }
  //   ),
  // )
  // inspect(
  //   formatted,
  //   content=(
  //     #|///|
  //     #|fn main {
  //     #|  println("Hello, world!")
  //     #|}
  //     #|
  //   ),
  // )

  // let formatted = try? @moon.format_string(
  //   (
  //     #|struct Point { x: Int, y: Int }
  //   ),
  // ) 

  // inspect(formatted)

}
