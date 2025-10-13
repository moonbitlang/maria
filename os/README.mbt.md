# `moonbitlang/maria/os`

Operating system environment variable access and manipulation.

## Overview

This package provides functions for reading, setting, and unsetting environment variables through the operating system's environment interface.

## Usage

### Reading Environment Variables

```moonbit
///|
test "get environment variable" {
  // Get an environment variable
  let home = @os.getenv("HOME")
  // Returns Some(value) if set, None if not found
  let _ = home
  
  let nonexistent = @os.getenv("NONEXISTENT_VAR")
  @json.inspect(nonexistent, content=None)
}
```

### Setting Environment Variables

```moonbit
///|
test "set environment variable" {
  // Set a new environment variable
  @os.setenv("MY_VAR", "my_value")
  
  // Get it back
  let value = @os.getenv("MY_VAR")
  @json.inspect(value, content=Some("my_value"))
  
  // Overwrite existing variable (default behavior)
  @os.setenv("MY_VAR", "new_value")
  @json.inspect(@os.getenv("MY_VAR"), content=Some("new_value"))
  
  // Don't overwrite if already set
  @os.setenv("MY_VAR", "another_value", overwrite=false)
  @json.inspect(@os.getenv("MY_VAR"), content=Some("new_value"))
}
```

### Unsetting Environment Variables

```moonbit
///|
test "unset environment variable" {
  @os.setenv("TEMP_VAR", "value")
  @os.unsetenv("TEMP_VAR")
  @json.inspect(@os.getenv("TEMP_VAR"), content=None)
}
```

### Getting Current Working Directory

```moonbit
///|
test "get current working directory" {
  let cwd = @os.cwd()
  // Returns the current working directory as a string
  let _ = cwd
}
```

## API Reference

### Functions

#### `getenv(key: StringView) -> String? raise`

Gets an environment variable value.

- **Parameters:**
  - `key`: The environment variable name
- **Returns:** `Some(value)` if the variable is set, `None` if not found
- **Raises:** System errors (rare)

#### `setenv(key: StringView, value: StringView, overwrite?: Bool = true) -> Unit raise`

Sets an environment variable.

- **Parameters:**
  - `key`: The environment variable name
  - `value`: The value to set
  - `overwrite`: Whether to overwrite existing value (default: `true`)
- **Raises:** `@errno.Errno` on system errors

#### `unsetenv(key: StringView) -> Unit raise`

Removes an environment variable.

- **Parameters:**
  - `key`: The environment variable name to remove
- **Raises:** `@errno.Errno` on system errors

#### `cwd() -> String raise`

Returns the current working directory.

- **Returns:** The absolute path of the current working directory
- **Raises:** `@errno.Errno` if the current directory cannot be determined

## Notes

- Environment variables are process-wide and affect all threads
- Variable names and values are UTF-8 encoded
- Changes to environment variables are visible to child processes
- This package uses C standard library functions for environment access
