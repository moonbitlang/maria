# `moonbitlang/maria/path`

Path manipulation utilities for Unix-style file paths.

## Overview

This package provides functions for working with Unix-style file paths, including operations for extracting path components, normalizing paths, joining paths, and computing relative paths.

## Usage

### Path Components

```moonbit
let path = "/home/user/file.txt"

// Get directory name
@path.dirname(path) // "/home/user"

// Get base name
@path.basename(path) // "file.txt"

// Get extension
@path.ext(path) // ".txt"

// Get stem (filename without extension)
@path.stem(path) // "file"
```

### Joining Paths

```moonbit
let joined = @path.join("/home/user", "documents/file.txt")
joined // "/home/user/documents/file.txt"

// Handles normalization
let normalized = @path.join("/home", "../tmp/./file.txt")
normalized // "/tmp/file.txt"
```

### Path Normalization

```moonbit
@path.normalize("/home/./user/../tmp") // "/home/tmp"
@path.normalize("../../file.txt") // "../../file.txt"
```

### Absolute vs Relative Paths

```moonbit
@path.is_absolute("/home/user") // true
@path.is_absolute("./file.txt") // false
@path.is_relative("docs/file.txt") // true
```

### Computing Relative Paths

```moonbit
let rel = @path.relative("/home/user/docs", "/home/user/images/pic.jpg")
rel // "../images/pic.jpg"
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
