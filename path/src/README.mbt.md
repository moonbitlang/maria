# illusory0x0/path

A MoonBit library for cross-platform path manipulation, supporting both Unix and Windows path styles with type-safe operations.

## Examples

### PathBuilder Usage

Demonstrates building paths using PathBuilder from a relative path.

```mbt
///|
test {
  let path = @path.Path::parse("./projects/")
  let builder = @path.PathBuilder::from_path(path)
  builder.set_extension("md")
  builder.set_basename("README")
  inspect(builder, content="projects/README.md")
  builder.add_directory("proj_1")

  // pop last file, and add new directory
  inspect(builder, content="projects/proj_1/")
}
```

Demonstrates building paths using PathBuilder from a Windows absolute path.

```mbt
///|
test {
  let path = @path.Path::parse("C:\\projects\\")
  let builder = @path.PathBuilder::from_path(path)
  builder.set_file(base="README", extension="md")
  inspect(builder, content="C:\\projects\\README.md")
  builder.add_directory("proj_1")

  // pop last file, and add new directory
  inspect(builder, content="C:\\projects\\proj_1\\")
}
```


### Simple Usage

Shows basic path operations like extracting file name, directory, and prefix.

```mbt
///|
test "Simple String Operations" {
  let path = @path.Path::parse("C:\\Users\\username\\Documents\\file.txt")
  inspect(path.file(), content="Some(file.txt)")
  inspect(path.directory()[:].join("\\"), content="Users\\username\\Documents")
  inspect(path.prefix(), content="C:\\")
}
```


### Type Safe Operations

Illustrates type-safe access to directory components for Unix paths.

```mbt
///|
test "type safe directory components" {
  let path = @path.Path::parse("/home/username/proj/src/")
  guard path is UPath(path) else { panic() }
  let parent_dir : ArrayView[@path.UnixPathComponent] = path.directory[0:path.directory.length() -
    1]
  @json.inspect(parent_dir, content=[
    ["UnixPathComponent", "home"],
    ["UnixPathComponent", "username"],
    ["UnixPathComponent", "proj"],
  ])
}
```


### Path Kinds Examples

Examples of different path kinds: relative and absolute for Unix and Windows.

```mbt
///|
test "Unix relative path" {
  let path = @path.Path::parse("home/username/proj/src/README.mbt.md")
  inspect(path.directory(), content="home/username/proj/src/")
  inspect(path.file().unwrap(), content="README.mbt.md")
  inspect(path.is_absolute(), content="false")
  inspect(path.is_relative(), content="true")
  inspect(path.is_root_path(), content="false")
}
```


```mbt
///|
test "Unix absolute path" {
  let path = @path.Path::parse("/home/username/proj/src/README.mbt.md")
  inspect(path.directory(), content="home/username/proj/src/")
  inspect(path.file().unwrap(), content="README.mbt.md")
  inspect(path.is_absolute(), content="true")
  inspect(path.is_relative(), content="false")
  inspect(path.is_root_path(), content="true")
}
```

```mbt
///|
test "Windows relative path" {
  let path = @path.Path::parse("Users\\username\\proj\\src\\README.mbt.md")
  // This is used for Debug output
  inspect(path.directory(), content="Users/username/proj/src/")
  inspect(path.file().unwrap(), content="README.mbt.md")
  inspect(path.is_absolute(), content="false")
  inspect(path.is_relative(), content="true")
  inspect(path.is_root_path(), content="false")
}
```

```mbt
///|
test "Windows absolute path" {
  let path = @path.Path::parse("C:\\Users\\username\\proj\\src\\README.mbt.md")
  // This is used for Debug output
  inspect(path.directory(), content="Users/username/proj/src/")
  inspect(path.file().unwrap(), content="README.mbt.md")
  inspect(path.is_absolute(), content="true")
  inspect(path.is_relative(), content="false")
  inspect(path.is_root_path(), content="true")
}
```


```mbt
///|
test "Windows relative root path" {
  let path = @path.Path::parse("\\Users\\username\\proj\\src\\README.mbt.md")
  // This is used for Debug output
  inspect(path.directory(), content="Users/username/proj/src/")
  inspect(path.file().unwrap(), content="README.mbt.md")
  inspect(path.is_absolute(), content="false")
  inspect(path.is_relative(), content="true")
  inspect(path.is_root_path(), content="true")
}
```