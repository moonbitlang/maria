# `moonbitlang/maria/readline/csi`

CSI (Control Sequence Introducer) codes for terminal control.

## Overview

This package provides ANSI escape sequences for controlling terminal behavior, including cursor movement, colors, and screen manipulation.

## Usage

### Cursor Movement

```moonbit
///|
test "cursor" {
  // Move cursor up
  print(@csi.cursor_up(5))
  
  // Move to position
  print(@csi.cursor_position(10, 20))
}
```

### Colors

```moonbit
///|
test "colors" {
  // Set foreground color
  print(@csi.fg_color(31))  // Red
  print("Error")
  print(@csi.reset())
}
```

### Screen Control

```moonbit
///|
test "screen" {
  // Clear screen
  print(@csi.clear_screen())
  
  // Clear line
  print(@csi.clear_line())
}
```

## API Reference

### Functions

#### Cursor Control
- `cursor_up(n: Int) -> String`: Move cursor up n lines
- `cursor_down(n: Int) -> String`: Move cursor down n lines
- `cursor_forward(n: Int) -> String`: Move cursor right n columns
- `cursor_back(n: Int) -> String`: Move cursor left n columns
- `cursor_position(row: Int, col: Int) -> String`: Move to position
- `save_cursor() -> String`: Save cursor position
- `restore_cursor() -> String`: Restore cursor position

#### Display Control
- `clear_screen() -> String`: Clear entire screen
- `clear_line() -> String`: Clear current line
- `erase_display(n: Int) -> String`: Erase display
- `erase_line(n: Int) -> String`: Erase line

#### Colors and Styles
- `fg_color(code: Int) -> String`: Set foreground color
- `bg_color(code: Int) -> String`: Set background color
- `reset() -> String`: Reset all attributes
- `bold() -> String`: Enable bold
- `underline() -> String`: Enable underline

## Color Codes

- 30-37: Standard colors (black, red, green, yellow, blue, magenta, cyan, white)
- 90-97: Bright colors
- 38;5;N: 256-color mode
- 38;2;R;G;B: RGB color

## Notes

- CSI sequences start with `\x1b[`
- Not all terminals support all sequences
- Use with raw terminal mode
- Terminal must support ANSI escape codes
