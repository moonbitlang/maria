# `moonbitlang/maria/readline`

Interactive line editing with history and completion support.

## Overview

This package provides a readline-like interface for building interactive command-line applications with line editing, history, and autocompletion.

## Usage

### Basic Readline

```moonbit
///|
test "readline" {
  // Create readline interface
  let rl = @readline.Readline::new(prompt="> ")
  
  // Read a line (blocks until input)
  // let line = rl.readline()
  
  let _ = rl
}
```

### With History

```moonbit
///|
test "history" {
  let rl = @readline.Readline::new(prompt="> ")
  
  // Add to history
  rl.add_history("previous command")
  
  // Navigate history with up/down arrows
  let _ = rl
}
```

### With Completion

```moonbit
///|
test "completion" {
  let rl = @readline.Readline::new(
    prompt="> ",
    completer=fn(text) {
      // Return possible completions
      ["help", "exit", "quit"].filter(fn(cmd) { cmd.starts_with(text) })
    }
  )
  
  let _ = rl
}
```

## API Reference

### Types

#### `Readline`

Interactive line editor.

**Methods:**
- `new(prompt: String, completer?: (String) -> Array[String]) -> Readline`: Creates new instance
- `readline() -> String?`: Reads a line (None on EOF)
- `add_history(line: String)`: Adds to history
- `set_prompt(prompt: String)`: Changes prompt

### Features

- Line editing with cursor movement
- History navigation (up/down arrows)
- Tab completion
- Emacs-style keybindings
- Unicode support

## Keybindings

- `Ctrl-A`: Move to beginning of line
- `Ctrl-E`: Move to end of line
- `Ctrl-B/Left`: Move back one character
- `Ctrl-F/Right`: Move forward one character
- `Ctrl-D`: Delete character or EOF
- `Ctrl-K`: Kill to end of line
- `Ctrl-U`: Kill to beginning of line
- `Up/Down`: Navigate history
- `Tab`: Trigger completion

## Notes

- Terminal must be in raw mode
- Uses CSI (Control Sequence Introducer) for terminal control
- Supports Unicode character width calculation
- History is in-memory (not persisted)
