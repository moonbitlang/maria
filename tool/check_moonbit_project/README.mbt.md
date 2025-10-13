# `moonbitlang/maria/tool/check_moonbit_project`

Type-checks a MoonBit project and reports diagnostics.

## Overview

This tool runs the MoonBit type checker on a project and returns errors, warnings, and other diagnostics. It supports checking patches/changes before they're applied.

## Parameters

- `project_path` (required): Path to the MoonBit project to check
- `diagnostic_limit` (optional): Maximum number of diagnostics to return
- `patch_code` (optional): Code patch to check before applying
- `patch_file_name` (optional): File name for the patch

## Behavior

### Normal Checking
- Runs `moon check` on the project
- Returns all type errors, warnings, and info messages
- Includes file location, line/column numbers, and error messages

### Patch Checking
- If `patch_code` is provided, checks it without modifying files
- Validates that changes will compile successfully
- Useful for verifying fixes before applying them

## Result Format

Returns diagnostics with:
- `message`: The error or warning message
- `severity`: "error", "warning", or "info"
- `location`: File path, line, and column numbers
- Additional context about the issue

## Use Cases

- Validating code changes before committing
- Checking if a project compiles
- Finding type errors and warnings
- Verifying patches and fixes
- Pre-commit validation
- Continuous integration checks

## Notes

- Part of the maria AI agent tool system
- Uses MoonBit's native type checker
- Can limit diagnostics to avoid overwhelming output
- Supports both full project and patch checking
- Does not modify files during patch checking
