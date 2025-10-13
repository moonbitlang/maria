# `moonbitlang/maria/spawn`

Process spawning and management utilities.

## Overview

This package provides functions for spawning external processes, managing process IDs, and sending signals to processes.

## Usage

### Spawning Processes

```moonbit
let status = @spawn.spawn(
  "echo",
  ["Hello, World!"]
)
// Returns exit status (0 for success)
status // 0
```

### Capturing Output

```moonbit
let output = StringBuilder::new()
let logger = Logger::new(output)
let status = @spawn.spawn(
  "echo",
  ["test"],
  output=logger
)
status // 0
let output_str = output.to_string()
// output_str contains "test\n"
let _ = output_str
```

### Custom Working Directory

```moonbit
let status = @spawn.spawn(
  "pwd",
  [],
  cwd="/tmp"
)
status // 0
```

### Process IDs

```moonbit
let pid = @spawn.getpid()      // Current process ID
let ppid = @spawn.getppid()    // Parent process ID
let _ = (pid, ppid)
```

### Sending Signals

```moonbit
let pid = @spawn.getpid()
// Send a signal to a process
// @spawn.kill(pid, @signal.sigtstp)
let _ = pid
```

## API Reference

### Functions

#### `spawn(command: StringView, arguments: Array[StringView], output?: &Logger, cwd?: StringView) -> Int`

Spawns an external process and waits for it to complete.

- **Parameters:**
  - `command`: The command to execute
  - `arguments`: Array of command-line arguments
  - `output`: Optional logger to capture stdout/stderr
  - `cwd`: Optional working directory for the process
- **Returns:** The exit status code of the process

#### `getpid() -> Int`

Returns the current process ID.

#### `getppid() -> Int`

Returns the parent process ID.

#### `kill(pid: Int, sig: Int) -> Unit raise @errno.Errno`

Sends a signal to a process.

- **Parameters:**
  - `pid`: The process ID to signal
  - `sig`: The signal number to send (e.g., from `@signal`)
- **Raises:** `@errno.Errno` on failure

## Notes

- Process spawning is asynchronous
- Output is merged stdout and stderr when using the `output` parameter
- Exit status 0 typically indicates success
- Signal numbers are platform-specific (use `@signal` package for constants)
