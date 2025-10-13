# `moonbitlang/maria/fs`

Async file system operations.

## Overview

This package provides asynchronous file system operations including reading, writing, directory listing, file stats, and more.

## Usage

### Reading Files

```moonbit
///|
test "read file" {
  let content = @fs.read_file("README.md")
  let text = content.text()
  let _ = text
}
```

### Writing Files

```moonbit
///|
test "write file" {
  @fs.write_to_file("/tmp/test.txt", "Hello, World!")
}
```

### Listing Directories

```moonbit
///|
test "list directory" {
  let entries = @fs.list_directory(".")
  // Returns array of file/directory names
  let _ = entries
}
```

### Creating Directories

```moonbit
///|
test "make directory" {
  @fs.mkdir("/tmp/mydir", permission=0o755)
  
  // Recursive creation
  @fs.make_directory("/tmp/a/b/c", recursive=true)
}
```

### Checking Existence

```moonbit
///|
test "file exists" {
  let exists = @fs.exists("README.md")
  let _ = exists
}
```

### File Stats

```moonbit
///|
test "file stats" {
  let stat = @fs.stat("README.md")
  let mtime = stat.mtime()  // Modification time
  let atime = stat.atime()  // Access time
  let _ = (mtime, atime)
}
```

### Removing Files/Directories

```moonbit
///|
test "remove" {
  @fs.remove("/tmp/test.txt")
  
  // Remove directory recursively
  @fs.rmdir("/tmp/mydir", recursive=true)
}
```

### Temporary Directories

```moonbit
///|
test "temp directory" {
  @fs.with_temporary_directory("test-XXXXXX", fn(tmpdir) {
    // Use tmpdir
    // Automatically cleaned up after function returns
  })
}
```

## API Reference

### Functions

#### `read_file(path: String) -> Bytes`

Reads a file's contents asynchronously.

#### `write_to_file(path: String, content: String) -> Unit`

Writes content to a file.

#### `list_directory(path: String) -> Array[String]`

Lists entries in a directory.

#### `mkdir(path: String, permission: Int) -> Unit raise`

Creates a directory with specified permissions.

#### `make_directory(path: String, recursive?: Bool) -> Unit`

Creates a directory, optionally creating parent directories.

#### `exists(path: String) -> Bool`

Checks if a path exists.

#### `stat(path: String) -> Stat raise`

Gets file/directory statistics.

#### `remove(path: String) -> Unit`

Removes a file.

#### `rmdir(path: String, recursive?: Bool) -> Unit`

Removes a directory.

#### `with_temporary_directory(template: String, fn: (String) -> T) -> T`

Creates a temporary directory, executes function, then cleans up.

#### `kind(path: String) -> FileKind`

Returns the file type (file, directory, symlink, etc.).

#### `resolve(path: String) -> String`

Resolves a path to its absolute form.

### Types

#### `Stat`

File statistics.

**Methods:**
- `mtime() -> Int64`: Modification time
- `atime() -> Int64`: Access time

#### `FileKind`

File type enumeration (File, Directory, Symlink, etc.).

## Notes

- All operations are asynchronous
- Supports Unix-style permissions (e.g., 0o755)
- Paths are resolved relative to current working directory
- Temporary directories use mkdtemp pattern (XXXXXX replaced with random chars)
- Errors raise exceptions with errno information
