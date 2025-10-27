///|
test "panic Ambiguous path" {
  let path = try! Path::parse("file.txt")
  inspect(path, content="file.txt")
}

///|
test "panic verbatim can not use in relative path" {
  let path = try! Path::parse("\\\\?\\\\file")
  inspect(path, content="\\\\?\\file")
  let path = try! Path::parse("\\\\?\\\\file.txt")
  inspect(path, content="\\\\?\\file.txt")
  let path = try! Path::parse("\\\\?\\\\folder\\")
  inspect(path, content="\\\\?\\folder\\")
  let path = try! Path::parse("\\\\?\\\\folder")
  inspect(path, content="\\\\?\\folder")
}
