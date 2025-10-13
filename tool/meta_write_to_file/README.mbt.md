# `moonbitlang/maria/tool/meta_write_to_file`

Enhanced file writing with automatic MoonBit formatting and error fixing.

## Overview

This advanced file writing tool automatically formats MoonBit code, detects syntax errors, and can attempt to fix them. It provides diff output and learning prompts for better code quality.

## Parameters

- `path` (required): File path to write to
- `description` (required): Description of changes being made
- `search` (optional): Pattern to search for and replace
- `replace` (optional): Replacement content (used with `search`)

## Behavior

### Standard Write
- Writes content to file
- Automatically runs MoonBit formatter if applicable
- Creates parent directories as needed

### Pattern Replacement
- When `search` and `replace` are provided
- Finds exact matches of `search` pattern
- Replaces with `replace` content
- Useful for targeted updates

### Automatic Formatting
- Detects MoonBit files (`.mbt` extension)
- Runs `moon fmt` automatically
- Ensures consistent code style

### Error Detection & Learning
- Checks for syntax errors after writing
- Provides learning prompts if errors are found
- Generates helpful feedback for fixing issues

## Result Format

Returns:
- `path`: File that was modified
- `message`: Summary of operation
- `diff`: Git-style diff of changes
- `learning_prompt`: Suggestions if errors detected (optional)

## Use Cases

- Writing formatted MoonBit code
- Automated code generation with quality checks
- Targeted code updates with pattern matching
- Ensuring code style consistency
- Learning from formatting issues
- Professional code output

## Notes

- Part of the maria AI agent tool system
- MoonBit-specific enhancements
- Automatic formatting on write
- Provides detailed change tracking via diffs
- Helps improve code quality over time
