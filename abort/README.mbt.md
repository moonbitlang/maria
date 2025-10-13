# `moonbitlang/maria/abort`

A utility package for aborting program execution with error messages and backtraces.

## Overview

This package provides a single function for gracefully aborting program execution with a descriptive error message and optional backtrace information.

## Usage

```moonbit
///|
test "abort example" {
  // This would abort the program with a message and backtrace
  // @abort.abort("Something went wrong")
  
  // In tests, we just verify the function exists
  let _ : Unit = @abort.abort("test message")
}
```

## API Reference

### `abort[T](msg: String) -> T`

Aborts program execution with the given message and prints a backtrace.

- **Parameters:**
  - `msg`: The error message to display before aborting
- **Returns:** Never returns (generic type `T` allows usage in any context)
- **Behavior:**
  - Prints "Aborted: {msg}" to stdout
  - Attempts to print a backtrace
  - Triggers a panic to terminate the program

## Notes

- This function requires the `@backtrace` package to be available
- The backtrace will only be available if backtrace support is properly initialized
- This is typically used for unrecoverable errors where continuing execution is not safe
