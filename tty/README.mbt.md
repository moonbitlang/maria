# `moonbitlang/maria/tty`

Terminal (TTY) utilities for working with terminal devices.

## Overview

This package provides utilities for interacting with terminal devices, including getting terminal window size and setting raw mode.

## Usage

### Getting Window Size

```moonbit
let size = @tty.window_size()
// size.row contains number of rows
// size.col contains number of columns
let _ = (size.row, size.col)
```

### Setting Raw Mode

```moonbit
// Set stdin (fd 0) to raw mode
// @tty.set_raw_mode(0)

// In raw mode:
// - Input is not line-buffered
// - Special characters are not processed
// - Echo is disabled
let _ = 0
```

## API Reference

### Types

#### `Size`

Terminal window size.

**Fields:**
- `row: Int`: Number of rows (lines)
- `col: Int`: Number of columns (characters)

**Traits:**
- `ToJson`: Can be converted to JSON

### Functions

#### `window_size() -> Size raise`

Gets the current terminal window size.

- **Returns:** `Size` with row and column counts
- **Raises:** `@errno.Errno` if the terminal size cannot be determined

#### `set_raw_mode(fd: Int) -> Unit raise`

Sets a file descriptor to raw mode.

- **Parameters:**
  - `fd`: File descriptor (typically 0 for stdin)
- **Raises:** `@errno.Errno` if raw mode cannot be set

## Raw Mode

Raw mode disables:
- Line buffering (input available immediately)
- Echo (typed characters not displayed)
- Special character processing (Ctrl+C, Ctrl+D, etc.)
- Canonical mode input editing

This is useful for:
- Interactive command-line applications
- Text editors
- Games
- Custom input handling

## Notes

- Window size detection works on Unix-like systems
- Raw mode affects the entire terminal, not just the process
- Remember to restore terminal settings on exit
- File descriptor 0 is typically stdin
- Use with caution in production code
