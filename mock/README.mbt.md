# `moonbitlang/maria/mock`

Mock file system utilities for testing.

## Overview

This package provides utilities for creating temporary directories and files for testing purposes. It automatically manages cleanup and provides a mock file system environment.

## Usage

### Creating a Temporary Directory

```moonbit
@async.with_task_group(g => {
  let dir = @mock.directory("test-dir")
  g.add_defer(() => dir.close())
  
  let path = dir.path()
  // path is something like "maria-mock-test-dir-XXXXXX"
  let _ = path
})
```

### Adding Files to Mock Directory

```moonbit
@async.with_task_group(g => {
  let dir = @mock.directory("test")
  g.add_defer(() => dir.close())
  
  let file_path = dir.add_file("test.txt", "Hello, World!")
  // File is created at dir.path() + "/test.txt"
  let content = @fs.read_file(file_path).text()
  content // "Hello, World!"
})
```

### Stripping CWD from Paths

```moonbit
@async.with_task_group(g => {
  let dir = @mock.directory("strip-test")
  g.add_defer(() => dir.close())
  
  let full_path = @path.join(dir.path(), "file.txt")
  let relative = dir.strip_cwd(full_path)
  relative // "./file.txt"
})
```

## API Reference

### Types

#### `Directory`

A temporary directory for testing.

**Methods:**
- `path() -> String`: Returns the absolute path to the temporary directory
- `add_file(name: String, content: String) -> String`: Creates a file in the directory with the given content
- `strip_cwd(path: String) -> String`: Converts absolute paths to relative paths starting with `./`
- `close()`: Cleans up the temporary directory (called automatically with defer)

### Functions

#### `directory(name: String) -> Directory`

Creates a new temporary directory.

- **Parameters:**
  - `name`: A descriptive name for the directory (used as part of the path)
- **Returns:** A `Directory` instance
- **Location:** Automatically includes source location for error reporting

## Notes

- Temporary directories are created in `.tmp/` relative to the project root
- Directory names follow the pattern `maria-mock-{name}-XXXXXX` where `XXXXXX` is random
- Always use with `add_defer(() => dir.close())` to ensure cleanup
- The `.tmp` directory is created if it doesn't exist
- Errors during directory operations include source location for debugging
- Files and subdirectories can be created within the mock directory
