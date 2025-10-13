# `moonbitlang/maria/signal`

Unix signal constants and handling.

## Overview

This package provides access to Unix signal constants for use with process signal handling.

## Usage

### Signal Constants

```moonbit
///|
test "signal constants" {
  // SIGTSTP - Terminal stop signal (Ctrl+Z)
  let sig = @signal.sigtstp
  let _ = sig
}
```

## API Reference

### Constants

#### `sigtstp: Int`

The SIGTSTP (terminal stop) signal number. This signal is typically sent when the user presses Ctrl+Z to suspend a foreground process.

## Notes

- Signal constants are platform-specific
- This package provides access to Unix signal numbers
- Use with `@spawn.kill()` to send signals to processes
- Additional signal constants may be added in the future
