///|
test "WinPrefix::VerbatimSymlink" {
  let path = Path::parse("\\\\?\\GLOBALROOT\\file")
  inspect(path, content="\\\\?\\GLOBALROOT\\file")
  let path = Path::parse("\\\\?\\GLOBALROOT\\file.txt")
  inspect(path, content="\\\\?\\GLOBALROOT\\file.txt")
  let path = Path::parse("\\\\?\\GLOBALROOT\\folder\\")
  inspect(path, content="\\\\?\\GLOBALROOT\\folder\\")
  let path = Path::parse("\\\\?\\GLOBALROOT")
  inspect(path, content="\\\\?\\GLOBALROOT\\")
}

///|
test "WinPrefix::VerbatimUNC" {
  let path = Path::parse("\\\\?\\UNC\\server\\share\\file")
  inspect(path, content="\\\\?\\UNC\\server\\share\\file")
  let path = Path::parse("\\\\?\\UNC\\server\\share\\file.log")
  inspect(path, content="\\\\?\\UNC\\server\\share\\file.log")
  let path = Path::parse("\\\\?\\UNC\\server\\share\\folder\\")
  inspect(path, content="\\\\?\\UNC\\server\\share\\folder\\")
  let path = Path::parse("\\\\?\\UNC\\server\\share")
  inspect(path, content="\\\\?\\UNC\\server\\share")
}

///|
test "WinPrefix::VerbatimVolumeLetter" {
  let path = Path::parse("\\\\?\\C:\\file")
  inspect(path, content="\\\\?\\C:\\file")
  let path = Path::parse("\\\\?\\C:\\file.md")
  inspect(path, content="\\\\?\\C:\\file.md")
  let path = Path::parse("\\\\?\\C:\\folder\\")
  inspect(path, content="\\\\?\\C:\\folder\\")
  let path = Path::parse("\\\\?\\C:")
  inspect(path, content="\\\\?\\C:\\")
}

///|
test "WinPrefix::VerbatimVolumeGUID" {
  let path = Path::parse(
    "\\\\?\\Volume{12345678-1234-1234-1234-1234567890AB}file",
  )
  inspect(
    path,
    content="\\\\?\\Volume{12345678-1234-1234-1234-1234567890AB}file\\",
  )
  let path = Path::parse(
    "\\\\?\\Volume{12345678-1234-1234-1234-1234567890AB}file.png",
  )
  inspect(
    path,
    content="\\\\?\\Volume{12345678-1234-1234-1234-1234567890AB}file.png\\",
  )
  let path = Path::parse(
    "\\\\?\\Volume{12345678-1234-1234-1234-1234567890AB}folder\\",
  )
  inspect(
    path,
    content="\\\\?\\Volume{12345678-1234-1234-1234-1234567890AB}folder\\",
  )
  let path = Path::parse("\\\\?\\Volume{12345678-1234-1234-1234-1234567890AB}")
  inspect(path, content="\\\\?\\Volume{12345678-1234-1234-1234-1234567890AB}\\")
}

///|
test "WinPrefix::DeviceNS" {
  let path = Path::parse("\\\\.\\COM56\\file")
  inspect(path, content="\\\\.\\COM56\\file")
  let path = Path::parse("\\\\.\\COM56\\file.bin")
  inspect(path, content="\\\\.\\COM56\\file.bin")
  let path = Path::parse("\\\\.\\COM56\\folder\\")
  inspect(path, content="\\\\.\\COM56\\folder\\")
  let path = Path::parse("\\\\.\\COM56")
  inspect(path, content="\\\\.\\COM56\\")
}

///|
test "WinPrefix::UNC" {
  let path = Path::parse("\\\\server\\share\\file")
  inspect(path, content="\\\\server\\share\\file")
  let path = Path::parse("\\\\server\\share\\file.log")
  inspect(path, content="\\\\server\\share\\file.log")
  let path = Path::parse("\\\\server\\share\\folder\\")
  inspect(path, content="\\\\server\\share\\folder\\")
  let path = Path::parse("\\\\server\\share")
  inspect(path, content="\\\\server\\share\\")
}

///|
test "WinPrefix::VolumeLetter" {
  let path = Path::parse("C:\\")
  inspect(path, content="C:\\")
  let path = Path::parse("C:\\file")
  inspect(path, content="C:\\file")
  let path = Path::parse("C:\\file.txt")
  inspect(path, content="C:\\file.txt")
  let path = Path::parse("C:\\folder\\")
  inspect(path, content="C:\\folder\\")
}

///|
test "Windows relative path" {
  let path = Path::parse(".\\folder\\file")
  inspect(path, content="folder\\file")
}

///|
test "Windows relative root path" {
  let path = Path::parse("\\folder\\file")
  inspect(path, content="\\folder\\file")
  let path = Path::parse("\\..\\folder\\file")
  inspect(path, content="\\folder\\file")
}

///|
test "Unix relative path" {
  let path = Path::parse("./folder/file")
  inspect(path, content="folder/file")
}

///|
test "Unix absolute path" {
  let path = Path::parse("/../folder/file")
  inspect(path, content="/folder/file")
  let path = Path::parse("/folder/file")
  inspect(path, content="/folder/file")
  let path = Path::parse("/")
  inspect(path, content="/")
}

///|
test "Unix path normalization" {
  let path = Path::parse("./a/b/./c/../d/../..")
  inspect(path, content="a/")
  let path = Path::parse("/a/b/..")
  inspect(path, content="/a/")
  let path = Path::parse("/../..")
  inspect(path, content="/")
  let path = Path::parse("/../a/b/../c/../../..")
  inspect(path, content="/")
  let path = Path::parse("/../a/b/../c/../..")
  inspect(path, content="/")
  let path = Path::parse("/../a/b/../c")
  inspect(path, content="/a/c")
}

///|
test "Windows path normalization" {
  let path = Path::parse(".\\a\\b\\.\\c\\..\\d\\..\\..")
  inspect(path, content="a\\")
  let path = Path::parse("\\a\\b\\..")
  inspect(path, content="\\a\\")
  let path = Path::parse("\\..\\..\\")
  inspect(path, content="\\")
  let path = Path::parse("\\..\\a\\b\\..\\c\\..\\..\\..")
  inspect(path, content="\\")
  let path = Path::parse("\\..\\a\\b\\..\\c\\..\\..")
  inspect(path, content="\\")
  let path = Path::parse("\\..\\a\\b\\..\\c")
  inspect(path, content="\\a\\c")
  let path = Path::parse("C:\\..\\..\\c\\..")
  inspect(path, content="C:\\")
}

///|
test "Unix relative path" {
  let path = Path::parse("containers/finger_tree")
  inspect(path, content="containers/finger_tree")
  let path = Path::parse("containers/finger_tree/finger_tree.mbt")
  inspect(path, content="containers/finger_tree/finger_tree.mbt")
}

///|
test "Windows relative path" {
  let path = Path::parse("containers\\finger_tree")
  inspect(path, content="containers\\finger_tree")
  let path = Path::parse("containers\\finger_tree\\finger_tree.mbt")
  inspect(path, content="containers\\finger_tree\\finger_tree.mbt")
}

///|
test "file extension" {
  let path = Path::parse("./README.mbt.md")
  let file = path.file().unwrap()
  @json.inspect(file, content={ "base": "README.mbt", "extension": "md" })
  inspect(path, content="README.mbt.md")
}

///|
test "Unix inner path normalization for slashes" {
  let path = Path::parse("./a//b////c")
  inspect(path, content="a/b/c")
}

///|
test "Windows inner path normalization for backslashes" {
  let path = Path::parse(".\\a\\\\b\\\\\\\\c")
  inspect(path, content="a\\b\\c")
}

///|
test "Windows backslashes normalization" {
  let path = Path::parse("C:\\\\\\\\a\\b")
  inspect(path, content="C:\\a\\b")
  let path = Path::parse(".\\\\\\a\\b\\c\\\\e")
  inspect(path, content="a\\b\\c\\e")
}

///|
test "Unix slashes normalization" {
  let path = Path::parse("///home/username/project")
  inspect(path, content="/home/username/project")
  let path = Path::parse(".//a/b//c/e////d")
  inspect(path, content="a/b/c/e/d")
}

///|
test "edge cases" {
  let path = Path::parse("/")
  inspect(path, content="/")
  let path = Path::parse("\\")
  inspect(path, content="\\")
  let path = Path::parse(".\\")
  inspect(path)
  let path = Path::parse("./")
  inspect(path)
  let path = Path::parse("//")
  inspect(path, content="//")
  let path = Path::parse("///")
  inspect(path, content="/")
}
