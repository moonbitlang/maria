///|
test "dirname" {
  @json.inspect(@path.dirname("a/b/c"), content="a/b")
}

///|
test "basename" {
  @json.inspect(@path.basename("a/b/c.jpg"), content="c.jpg")
}

///|
test "ext" {
  @json.inspect(@path.ext("a/b/c.jpg"), content=".jpg")
}

///|
test "stem" {
  @json.inspect(@path.stem("a/b/c.jpg"), content="c")
}

///|
test "join" {
  @json.inspect(@path.join("a", "b"), content=("a/b"))
}
