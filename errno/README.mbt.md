# `moonbitlang/maria/errno`

System error number (errno) support for Unix-style systems.

## Overview

This package provides access to system error codes and error messages from the C standard library's errno facility.

## Usage

### Error Constants

```moonbit
///|
test "errno constants" {
  // ERANGE - Result too large
  let _ = @errno.erange
  
  // ENAMETOOLONG - File name too long
  let _ = @errno.enametoolong
}
```

### Error Messages

```moonbit
///|
test "errno to string" {
  let err = @errno.Errno(@errno.erange)
  let msg = err.to_string()
  // Returns human-readable error message like "Numerical result out of range"
  let _ = msg
}
```

### Using with ToJson

```moonbit
///|
test "errno json" {
  let err = @errno.Errno(@errno.enametoolong)
  let json = err.to_json()
  // Converts to JSON string representation
  let _ = json
}
```

## API Reference

### Types

#### `Errno`

A suberror type wrapping an integer error number.

**Traits:**
- `Show`: Converts errno to human-readable error message
- `ToJson`: Converts errno to JSON string

### Constants

#### `erange: Int`

Error constant for "Result too large" (ERANGE).

#### `enametoolong: Int`

Error constant for "File name too long" (ENAMETOOLONG).

## Notes

- Error messages are obtained from the system's `strerror()` function
- If an error message cannot be retrieved, the errno number is displayed
- This package wraps C library error codes and is platform-dependent
- Additional errno constants can be accessed through the underlying C interface
