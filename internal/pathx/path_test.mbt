///|
test "basename" {
  json_inspect(@pathx.basename("a/b/c.jpg"), content="c.jpg")
  json_inspect(@pathx.basename("a/b/c/"), content="c")
  json_inspect(@pathx.basename("a"), content="a")
}

///|
test "stem/ext" {
  // property: `stem(path) + ext(path) == basename(path)`
  json_inspect(@pathx.stem("a/b/c.jpg"), content="c")
  //
  json_inspect(@pathx.stem("a/b/c"), content="c")
  //
  json_inspect(@pathx.stem("a/b.c/d"), content="d")
}

///|
test "split" {
  json_inspect(@pathx.split("a/b/c.jpg").collect(), content=["a", "b", "c.jpg"])
  json_inspect(@pathx.split("a//c.jpg").collect(), content=["a", "c.jpg"])
  json_inspect(@pathx.split("///").collect(), content=["/"])
  json_inspect(@pathx.split("//").collect(), content=["//"])
  json_inspect(@pathx.split("").collect(), content=[])
  json_inspect(@pathx.split("c/").collect(), content=["c"])
  json_inspect(@pathx.split("/c").collect(), content=["/", "c"])
  json_inspect(@pathx.split("/").collect(), content=["/"])
  json_inspect(@pathx.split("a/b/../c/./d//e").collect(), content=[
    "a", "b", "..", "c", ".", "d", "e",
  ])
  json_inspect(@pathx.split("/a/b/../c/./d//e").collect(), content=[
    "/", "a", "b", "..", "c", ".", "d", "e",
  ])
}

///|
test "replace_ext" {
  let path = "main.mbt"
  inspect(replace_ext(path, ".c"), content="main.c")
  let path = "main"
  inspect(replace_ext(path, ".mbt"), content="main.mbt")
  let path = "main.com/file"
  inspect(replace_ext(path, ".c"), content="main.com/file.c")
}

///|
test "replace_ext: failed cases" {
  // This test cases define `replace_ext` undefined behavior.
  // user should not abuse this behavior in some uncommon cases.
  //
  // some input would disappear when path is resolved and normalized.
  let ext = ".md"
  // empty file name.
  inspect(replace_ext("", ext), content="")
  // special file name.
  inspect(replace_ext(".", ext), content=".")
  inspect(replace_ext("..", ext), content="..")
  // POSIX platform specific cases
  inspect(replace_ext("//", ext), content="//")
  // root cases
  inspect(replace_ext("/", ext), content="/")
  inspect(replace_ext("///", ext), content="///")
}
