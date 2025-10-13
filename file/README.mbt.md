# `moonbitlang/maria/file`

File manager for tracking file access times in a working directory context.

## Overview

This package provides a simple file manager that tracks file access within a specific working directory. It's primarily used internally for managing file state.

## Usage

### Creating a File Manager

```moonbit
///|
test "create file manager" {
  let manager = @file.manager(cwd="/home/user/project")
  let _ = manager
}
```

## API Reference

### Types

#### `Manager`

A file manager that tracks file access times.

**Fields:**
- `cwd: String`: The current working directory
- `access: Map[String, Int64]`: Map of file paths to their last access times

### Functions

#### `manager(cwd~: String) -> Manager`

Creates a new file manager.

- **Parameters:**
  - `cwd`: The current working directory for this manager
- **Returns:** A new `Manager` instance

## Notes

- This is a utility package used internally for file state management
- Access times are stored as `Int64` values
- The manager maintains a map of file paths to access timestamps
