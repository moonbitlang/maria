# `moonbitlang/maria/path`

Path manipulation utilities for Unix-style file paths.

## Overview

This package provides functions for working with Unix-style file paths, including operations for extracting path components, normalizing paths, joining paths, and computing relative paths.

## Usage

### Path Components

```moonbit
///|
test "path components" {
  let path = "/home/user/file.txt"
  
  // Get directory name
  @json.inspect(@path.dirname(path), content="/home/user")
  
  // Get base name
  @json.inspect(@path.basename(path), content="file.txt")
  
  // Get extension
  @json.inspect(@path.ext(path), content=".txt")
  
  // Get stem (filename without extension)
  @json.inspect(@path.stem(path), content="file")
}
```

### Joining Paths

```moonbit
///|
test "join paths" {
  let joined = @path.join("/home/user", "documents/file.txt")
  @json.inspect(joined, content="/home/user/documents/file.txt")
  
  // Handles normalization
  let normalized = @path.join("/home", "../tmp/./file.txt")
  @json.inspect(normalized, content="/tmp/file.txt")
}
```

### Path Normalization

```moonbit
///|
test "normalize path" {
  @json.inspect(@path.normalize("/home/./user/../tmp"), content="/home/tmp")
  @json.inspect(@path.normalize("../../file.txt"), content="../../file.txt")
}
```

### Absolute vs Relative Paths

```moonbit
///|
test "absolute paths" {
  @json.inspect(@path.is_absolute("/home/user"), content=true)
  @json.inspect(@path.is_absolute("./file.txt"), content=false)
  @json.inspect(@path.is_relative("docs/file.txt"), content=true)
}
```

### Computing Relative Paths

```moonbit
///|
test "relative path" {
  let rel = @path.relative("/home/user/docs", "/home/user/images/pic.jpg")
  @json.inspect(rel, content="../images/pic.jpg")
}
```

## API Reference

### Functions

#### `dirname(path: StringView) -> StringView`

Returns the directory portion of a path.

#### `basename(path: StringView) -> StringView`

Returns the final component of a path.

#### `ext(path: StringView) -> StringView`

Returns the file extension including the leading dot.

#### `stem(path: StringView) -> StringView`

Returns the filename without its extension.

#### `split(view: StringView) -> Iter[StringView]`

Splits a path into components.

#### `normalize(view: StringView) -> String`

Normalizes a path, resolving `.` and `..` references.

#### `join(p: StringView, q: StringView) -> String`

Joins two paths and normalizes the result.

#### `is_absolute(path: StringView) -> Bool`

Returns `true` if the path is absolute (starts with `/`).

#### `is_relative(path: StringView) -> Bool`

Returns `true` if the path is relative.

#### `relative(from: StringView, to: StringView) -> String raise`

Computes the relative path from `from` to `to`.

#### `resolve(view: StringView) -> String raise`

Resolves a path to an absolute path. Relative paths are resolved against the current working directory.

### Constants

- `sep: Char`: The path separator character (`'/'`)

## Notes

- All functions use Unix-style path separators (`/`)
- Path normalization follows standard Unix semantics
- Functions may raise errors when accessing the file system (e.g., `resolve`)
- Empty paths are treated as `.` (current directory)
