///|
test "dirname" {
  @json.inspect(@path.dirname("a/b/c") == "a/b", content=true)
}

///|
test "basename" {
  @json.inspect(@encoding/utf8.decode(@path.basename("a/b/c.jpg")), content="c.jpg")
}

///|
test "ext" {
  @json.inspect(@encoding/utf8.decode(@path.ext("a/b/c.jpg")), content=".jpg")
}

///|
test "stem" {
  @json.inspect(@encoding/utf8.decode(@path.stem("a/b/c.jpg")), content="c")
}
