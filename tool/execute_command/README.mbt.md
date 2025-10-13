# `moonbitlang/maria/tool/execute_command`

Executes shell commands with timeout and output capture.

## Overview

This tool allows AI agents to execute shell commands with configurable timeouts and output handling. Useful for running build commands, tests, or any command-line operations.

## Parameters

- `command` (required): The shell command to execute
- `timeout_ms` (optional): Timeout in milliseconds (default varies)
- `cwd` (optional): Working directory for command execution

## Behavior

- Executes the command in a shell environment
- Captures both stdout and stderr (merged)
- Enforces timeout limits to prevent hanging
- Returns structured output with exit code

## Result Format

Returns a `CommandResult` with:
- `command`: The executed command string
- `exit_code`: Process exit code (0 = success)
- `output`: Combined stdout/stderr output
- `truncated`: Whether output was truncated
- `total_lines`: Total number of output lines
- `timeout_ms`: Timeout value used
- `output_file`: Optional path to full output file (if truncated)

## Use Cases

- Running build commands (`moon build`, `moon test`)
- Executing code linters and formatters
- Running shell scripts
- Git operations
- File system commands
- Running development tools

## Notes

- Part of the maria AI agent tool system
- Commands run in shell environment (has access to PATH)
- Output is captured and may be truncated for large outputs
- Exit code 0 indicates success, non-zero indicates failure
- Timeout prevents infinite or hanging processes
