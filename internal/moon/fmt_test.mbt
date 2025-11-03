///|
async test "format_string" {
  let input = [
    (
      #|fn main {println("Hello, world!")}
    ),
    (
      #|struct Point {x: Int,y: Int}
    ),
    (
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
    {
      "Ok": "enum Color {\n  Red,\n  Green,\n  Blue,\n}\n\nfn Color::to_string(self : Color) -> String {\n  switch self {\n    Red => \"red\",\n    Green => \"green\",\n    Blue => \"blue\",\n  }\n}\n\nfn main() {\n\n  let color : Color = Blue\n  println(color.to_string())\n}\n",
    },
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
