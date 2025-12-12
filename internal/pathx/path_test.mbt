///|
test "dirname" {
  @json.inspect(@pathx.dirname("a/b/c"), content="a/b")
  @json.inspect(@pathx.dirname("a/b/c/"), content="a/b/c")
  @json.inspect(@pathx.dirname("a"), content=".")
  @json.inspect(@pathx.dirname("a/"), content="a")
  @json.inspect(@pathx.dirname("/"), content="/")
  @json.inspect(@pathx.dirname("//"), content="//")
  @json.inspect(@pathx.dirname("///"), content="/")
  @json.inspect(@pathx.dirname("////"), content="/")
  @json.inspect(@pathx.dirname("/a"), content="/")
  @json.inspect(@pathx.dirname("//a"), content="//")
  @json.inspect(@pathx.dirname("///a"), content="/")
  @json.inspect(@pathx.dirname("/a/b/c//a"), content="/a/b/c")
  @json.inspect(@pathx.dirname("//a/b/c//a"), content="//a/b/c")
  @json.inspect(@pathx.dirname("///a/b/c//a"), content="///a/b/c")
  @json.inspect(@pathx.dirname("c///a"), content="c")
  @json.inspect(@pathx.dirname(""), content=".")
}

///|
test "basename" {
  @json.inspect(@pathx.basename("a/b/c.jpg"), content="c.jpg")
  @json.inspect(@pathx.basename("a/b/c/"), content="c")
  @json.inspect(@pathx.basename("a"), content="a")
}

///|
test "stem/ext" {
  // property: `stem(path) + ext(path) == basename(path)`
  @json.inspect(@pathx.stem("a/b/c.jpg"), content="c")
  @json.inspect(@pathx.ext("a/b/c.jpg"), content=".jpg")
  //
  @json.inspect(@pathx.stem("a/b/c"), content="c")
  @json.inspect(@pathx.ext("a/b/c"), content="")
  //
  @json.inspect(@pathx.stem("a/b.c/d"), content="d")
  @json.inspect(@pathx.ext("a/b.c/d"), content="")
}

///|
test "join" {
  @json.inspect(@pathx.join("a", "b"), content="a/b")
  @json.inspect(@pathx.join("a/", "b"), content="a/b")
  @json.inspect(@pathx.join("a", "/b"), content="/b")
  @json.inspect(@pathx.join("a/", "/b"), content="/b")
  @json.inspect(@pathx.join("a", "b/"), content="a/b")
  @json.inspect(@pathx.join("a/", "b/"), content="a/b")
  @json.inspect(@pathx.join("", "b"), content="b")
  @json.inspect(@pathx.join("a", ""), content="a")
  @json.inspect(@pathx.join("", ""), content="")
  @json.inspect(@pathx.join(".", "b"), content="b")
  @json.inspect(@pathx.join("a", "."), content="a")
  @json.inspect(@pathx.join(".", "."), content="")
  @json.inspect(@pathx.join("a/b", "c/d"), content="a/b/c/d")
  @json.inspect(@pathx.join("a/b/", "c/d"), content="a/b/c/d")
  @json.inspect(@pathx.join("a/b", "c/d/"), content="a/b/c/d")
  @json.inspect(@pathx.join("a/b/", "c/d/"), content="a/b/c/d")
  @json.inspect(@pathx.join("a/b", "../c/d"), content="a/c/d")
  @json.inspect(@pathx.join("a/b/", "../c/d"), content="a/c/d")
  @json.inspect(@pathx.join("a/b", "../c/d/"), content="a/c/d")
  @json.inspect(@pathx.join("a/b/", "../c/d/"), content="a/c/d")
  @json.inspect(@pathx.join("a/b", "../../c/d"), content="c/d")
  @json.inspect(@pathx.join("a/b", "../../../c/d"), content="../c/d")
}

///|
test "split" {
  @json.inspect(@pathx.split("a/b/c.jpg").collect(), content=["a", "b", "c.jpg"])
  @json.inspect(@pathx.split("a//c.jpg").collect(), content=["a", "c.jpg"])
  @json.inspect(@pathx.split("///").collect(), content=["/"])
  @json.inspect(@pathx.split("//").collect(), content=["//"])
  @json.inspect(@pathx.split("").collect(), content=[])
  @json.inspect(@pathx.split("c/").collect(), content=["c"])
  @json.inspect(@pathx.split("/c").collect(), content=["/", "c"])
  @json.inspect(@pathx.split("/").collect(), content=["/"])
  @json.inspect(@pathx.split("a/b/../c/./d//e").collect(), content=[
    "a", "b", "..", "c", ".", "d", "e",
  ])
  @json.inspect(@pathx.split("/a/b/../c/./d//e").collect(), content=[
    "/", "a", "b", "..", "c", ".", "d", "e",
  ])
}

///|
test "normalize" {
  @json.inspect(@pathx.normalize("a/b/../c/./d//e"), content="a/c/d/e")
  @json.inspect(@pathx.normalize("a/b/../../c/./d//e"), content="c/d/e")
  @json.inspect(@pathx.normalize("a/b/../../../c/./d//e"), content="../c/d/e")
  @json.inspect(@pathx.normalize("/a/b/../c/./d//e"), content="/a/c/d/e")
  @json.inspect(@pathx.normalize("/a/b/../../c/./d//e"), content="/c/d/e")
  @json.inspect(@pathx.normalize("/a/b/../../../c/./d//e"), content="/c/d/e")
  @json.inspect(@pathx.normalize("a/b/c/.."), content="a/b")
  @json.inspect(@pathx.normalize("a/b/c/."), content="a/b/c")
  @json.inspect(@pathx.normalize("a/b/c//"), content="a/b/c")
  @json.inspect(@pathx.normalize("a//b//c"), content="a/b/c")
  @json.inspect(@pathx.normalize("////a//b//c"), content="/a/b/c")
  @json.inspect(@pathx.normalize("//a//b//c"), content="//a/b/c")
  @json.inspect(@pathx.normalize("////"), content="/")
  @json.inspect(@pathx.normalize(".."), content="..")
  @json.inspect(@pathx.normalize("../.."), content="../..")
  @json.inspect(@pathx.normalize("../../.."), content="../../..")
  @json.inspect(@pathx.normalize("../../c/d"), content="../../c/d")
  @json.inspect(@pathx.normalize("."), content="")
  @json.inspect(@pathx.normalize(""), content="")
}

///|
test "relative" {
  @json.inspect(@pathx.relative("a/b/c", "a/b/c"), content=".")
  @json.inspect(@pathx.relative("a/b/c", "a/b/d"), content="../d")
  @json.inspect(@pathx.relative("a/b/c", "a/d/e"), content="../../d/e")
  @json.inspect(@pathx.relative("a/b/c", "d/e/f"), content="../../../d/e/f")
  // @json.inspect(@pathx.relative("../a", "b"), content="../maria/b")
  @json.inspect(@pathx.relative("a", "../b"), content="../../b")
  @json.inspect(@pathx.relative("/a/b/c", "/a/b/c"), content=".")
  @json.inspect(@pathx.relative("/a/b/c", "/a/b/d"), content="../d")
  @json.inspect(@pathx.relative("/a/b/c", "/a/d/e"), content="../../d/e")
  @json.inspect(@pathx.relative("/a/b/c", "/d/e/f"), content="../../../d/e/f")
}

///|
test "resolve" {

}

///|
test "choose second if absolute" {
  let p = "/var/folders/rd/k3wf07sd32g2cdsy6q13jp3c0000gn/T/"
  let q = "/var/folders/rd/k3wf07sd32g2cdsy6q13jp3c0000gn/T/moonbit-taco-XXXXXXX"
  inspect(
    @pathx.join(p, q),
    content="/var/folders/rd/k3wf07sd32g2cdsy6q13jp3c0000gn/T/moonbit-taco-XXXXXXX",
  )
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
